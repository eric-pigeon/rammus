module Rammus
  RSpec.describe Target, browser: true do
    before { @_context = browser.create_context }
    after { @_context.close }
    let(:context) { @_context }
    let!(:page) { context.new_page }

    describe 'Target' do
      it 'Browser#targets should return all of the targets' do
        # The pages will be the testing page and the original newtab page
        targets = browser.targets
        blank_page = targets.any? { |target| target.type == "page" && target.url == "about:blank" }
        expect(blank_page).to eq true
        expect(targets.any? { |target| target.type == 'browser' }).to eq true
      end

      it 'Browser.pages should return all of the pages' do
        # The pages will be the testing page
        all_pages = context.pages
        expect(all_pages.length).to eq 1
        expect(all_pages).to include page
        expect(all_pages[0]).not_to eq(all_pages[1])
      end

      it 'should contain browser target' do
        targets = browser.targets
        browser_target = targets.detect { |target| target.type == 'browser' }
        expect(browser_target).not_to be_nil
      end

      it 'should be able to use the default page in the browser' do
        # The pages will be the testing page and the original newtab page
        all_pages = browser.pages
        original_page = all_pages.detect { |p| p != page }
        expect(original_page.evaluate_function("() => ['Hello', 'world'].join(' ')").value).to eq 'Hello world'
        expect(original_page.query_selector 'body').not_to be_nil
      end

      it 'should report when a new page is created and closed' do
        other_page, _ = Concurrent::Promises.zip(
          context.wait_for_target { |target| target.url == server.cross_process_domain + 'empty' }.then { |target| target.page },
          page.evaluate_function("url => { window.open(url) }", server.cross_process_domain + 'empty')
        ).value
        expect(other_page.url).to include server.cross_process_domain

        expect(other_page.evaluate_function("() => ['Hello', 'world'].join(' ')").value).to eq 'Hello world'
        expect(other_page.query_selector 'body').not_to be_nil

        all_pages = context.pages
        expect(all_pages).to include page
        expect(all_pages).to include other_page

        close_page_promise = Concurrent::Promises.resolvable_future.tap do |future|
          context.once :target_destroyed, -> (target) { future.fulfill(target.page) }
        end
        other_page.close
        expect(close_page_promise.value).to eq other_page

        all_pages = context.targets.map { |target| target.page }.compact
        expect(all_pages).to include page
        expect(all_pages).not_to include other_page
      end

      it 'should report when a service worker is created and destroyed' do
        page.goto(server.empty_page).wait!
        created_target = Concurrent::Promises.resolvable_future.tap do |future|
          context.once :target_created, -> target { future.fulfill(target) }
        end

        page.goto(server.domain + 'serviceworkers/empty/sw.html').wait!

        expect((created_target.value!).type).to eq 'service_worker'
        expect((created_target.value!).url).to eq server.domain + 'serviceworkers/empty/sw.js'

        destroyed_target = Concurrent::Promises.resolvable_future.tap do |future|
          context.once :target_destroyed, -> (target) { future.fulfill(target) }
        end
        page.evaluate_function('() => window.registrationPromise.then(registration => registration.unregister())').wait!
        expect(destroyed_target.value).to eq(created_target.value)
      end

      xit 'should create a worker from a service worker' do
        # TODO
        page.goto(server.domain + 'serviceworkers/empty/sw.html').wait!

        target = context.wait_for_target { |t| t.type == 'service_worker' }.value
        worker = target.worker
        expect(worker.evaluate_function('() => self.toString()').value).to eq '[object ServiceWorkerGlobalScope]'
      end

      xit 'should create a worker from a shared worker' do
        page.goto(server.empty_page).wait!
        page.evaluate_function("() => { new SharedWorker('data:text/javascript,console.log(\"hi\")'); }").wait!
        target = context.wait_for_target { |t| t.type == 'shared_worker' }.value
        worker = target.worker.value
        expect(worker.evaluate_function('() => self.toString()').value).to eq '[object SharedWorkerGlobalScope]'
      end

      it 'should report when a target url changes' do
        page.goto(server.empty_page).wait!
        changed_target = Concurrent::Promises.resolvable_future.tap do |future|
          context.once :target_changed, -> (target) { future.fulfill(target) }
        end
        page.goto(server.cross_process_domain).wait!
        expect((changed_target.value).url).to eq server.cross_process_domain

        changed_target = Concurrent::Promises.resolvable_future.tap do |future|
          context.once :target_changed, -> (target) { future.fulfill(target) }
        end
        page.goto(server.empty_page).wait!
        expect((changed_target.value).url).to eq server.empty_page
      end

      it 'should not report uninitialized pages' do
        target_changed = false
        listener = -> (_target) { target_changed = true }
        context.on :target_changed, listener

        target_promise = Concurrent::Promises.resolvable_future.tap do |future|
          context.once :target_created, -> (target) { future.fulfill(target) }
        end
        new_page = context.new_page
        target = target_promise.value
        expect(target.url).to eq 'about:blank'

        target_promise_2 = Concurrent::Promises.resolvable_future.tap do |future|
          context.once :target_created, -> (target) { future.fulfill(target) }
        end
        new_page.evaluate_function("() => { window.open('about:blank') }").wait!

        target_2 = target_promise_2.value
        expect(target_2.url).to eq 'about:blank'
        new_page.close
        expect(target_changed).to eq false
        context.remove_listener :target_changed, listener
      end

      it 'should not crash while redirecting if original request was missed' do
        server_response = nil
        server.set_route '/one-style.css' do |_req, res|
          Concurrent::Promises.resolvable_future
            .tap { |f| server_response = f.method :fulfill }
            .then { res.redirect '/injectedstyle.css'; res.finish }
            .value!
        end
        # Open a new page. Use window.open to connect to the page later.
        Concurrent::Promises.zip(
          page.evaluate_function("url => window.open(url)", server.domain + 'one-style.html'),
          server.wait_for_request('/one-style.css')
        ).wait!
        # Connect to the opened page.
        target = context.wait_for_target { |target| target.url.include?('one-style.html') }.value
        new_page = target.page
        server_response.call nil
        # Wait for the new page to load.
        wait_event(new_page, :load).wait!
        # Cleanup.
        new_page.close
      end

      # TODO
      #it('should have an opener', async({page, server, context}) => {
      #  await page.goto(server.EMPTY_PAGE);
      #  const [createdTarget] = await Promise.all([
      #    new Promise(fulfill => context.once('targetcreated', target => fulfill(target))),
      #    page.goto(server.PREFIX + '/popup/window-open.html')
      #  ]);
      #  expect((await createdTarget.page()).url()).toBe(server.PREFIX + '/popup/popup.html');
      #  expect(createdTarget.opener()).toBe(page.target());
      #  expect(page.target().opener()).toBe(null);
      #});
    end

    describe 'Browser#wait_for_target' do
      # TODO
      #it('should wait for a target', async function({browser, server}) {
      #  let resolved = false;
      #  const targetPromise = browser.waitForTarget(target => target.url() === server.EMPTY_PAGE);
      #  targetPromise.then(() => resolved = true);
      #  const page = await browser.newPage();
      #  expect(resolved).toBe(false);
      #  await page.goto(server.EMPTY_PAGE);
      #  const target = await targetPromise;
      #  expect(await target.page()).toBe(page);
      #  await page.close();
      #});
      #

      it 'should timeout waiting for a non-existent target' do
        expect do
          browser.wait_for_target(timeout: 0.10) { |target| target.url == server.empty_page }.wait!
        end.to raise_error Timeout::Error, "waiting for target failed: timeout 0.1s exceeded."
      end
    end
  end
end
