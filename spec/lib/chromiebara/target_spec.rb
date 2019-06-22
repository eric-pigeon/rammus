module Chromiebara
  RSpec.describe Target, browser: true do
    include Promise::Await
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
        expect(await original_page.evaluate_function "() => ['Hello', 'world'].join(' ')").to eq 'Hello world'
        expect(original_page.query_selector 'body').not_to be_nil
      end

      it 'should report when a new page is created and closed' do
        other_page, _ = await Promise.all(
          context.wait_for_target { |target| target.url == server.cross_process_domain + 'empty' }.then { |target| target.page },
          page.evaluate_function("url => { window.open(url) }", server.cross_process_domain + 'empty')
        )
        expect(other_page.url).to include server.cross_process_domain

        expect(await other_page.evaluate_function "() => ['Hello', 'world'].join(' ')").to eq 'Hello world'
        expect(other_page.query_selector 'body').not_to be_nil

        all_pages = context.pages
        expect(all_pages).to include page
        expect(all_pages).to include other_page

        close_page_promise = Promise.new do |resolve, _reject|
          context.once :target_destroyed, -> (target) { resolve.(target.page) }
        end
        other_page.close
        expect(await close_page_promise).to eq other_page

        all_pages = context.targets.map { |target| target.page }.compact
        expect(all_pages).to include page
        expect(all_pages).not_to include other_page
      end

      it 'should report when a service worker is created and destroyed' do
        page.goto server.empty_page
        created_target = Promise.new do |resolve, _reject|
          context.once :target_created, -> target { resolve.(target) }
        end

        page.goto server.domain + 'serviceworkers/empty/sw.html'

        expect((await created_target).type).to eq 'service_worker'
        expect((await created_target).url).to eq server.domain + 'serviceworkers/empty/sw.js'

        destroyed_target = Promise.new do |resolve, _reject|
          context.once :target_destroyed, -> (target) { resolve.(target) }
        end
        await page.evaluate_function '() => window.registrationPromise.then(registration => registration.unregister())'
        expect(await destroyed_target).to eq(await created_target)
      end

      xit 'should create a worker from a service worker' do
        # TODO
        page.goto server.domain + 'serviceworkers/empty/sw.html'

        target = await context.wait_for_target { |t| t.type == 'service_worker' }
        worker = target.worker
        expect(await worker.evaluate_function '() => self.toString()').to eq '[object ServiceWorkerGlobalScope]'
      end

      xit 'should create a worker from a shared worker' do
        page.goto server.empty_page
        await page.evaluate_function "() => { new SharedWorker('data:text/javascript,console.log(\"hi\")'); }"
        target = await context.wait_for_target { |t| t.type == 'shared_worker' }
        worker = await target.worker
        expect(await worker.evaluate_function('() => self.toString()')).to eq '[object SharedWorkerGlobalScope]'
      end

      it 'should report when a target url changes' do
        page.goto server.empty_page
        changed_target = Promise.new do |resolve, _reject|
          context.once :target_changed, -> (target) { resolve.(target) }
        end
        page.goto server.cross_process_domain
        expect((await changed_target).url).to eq server.cross_process_domain


        changed_target = Promise.new do |resolve, _reject|
          context.once :target_changed, -> (target) { resolve.(target) }
        end
        page.goto server.empty_page
        expect((await changed_target).url).to eq server.empty_page
      end

      it 'should not report uninitialized pages' do
        target_changed = false
        listener = -> (_target) { target_changed = true }
        context.on :target_changed, listener

        target_promise = Promise.new do |resolve, _reject|
          context.once :target_created, -> (target) { resolve.(target) }
        end
        new_page = context.new_page
        target = await target_promise
        expect(target.url).to eq 'about:blank'

        target_promise_2 = Promise.new do |resolve, _reject|
          context.once :target_created, -> (t) { resolve.(t) }
        end
        await new_page.evaluate_function "() => { window.open('about:blank') }"

        target_2 = await target_promise_2
        expect(target_2.url).to eq 'about:blank'
        new_page.close
        expect(target_changed).to eq false
        context.remove_listener :target_changed, listener
      end

      # TODO
      #it('should not crash while redirecting if original request was missed', async({page, server, context}) => {
      #  let serverResponse = null;
      #  server.setRoute('/one-style.css', (req, res) => serverResponse = res);
      #  // Open a new page. Use window.open to connect to the page later.
      #  await Promise.all([
      #    page.evaluate(url => window.open(url), server.PREFIX + '/one-style.html'),
      #    server.waitForRequest('/one-style.css')
      #  ]);
      #  // Connect to the opened page.
      #  const target = await context.waitForTarget(target => target.url().includes('one-style.html'));
      #  const newPage = await target.page();
      #  // Issue a redirect.
      #  serverResponse.writeHead(302, { location: '/injectedstyle.css' });
      #  serverResponse.end();
      #  // Wait for the new page to load.
      #  await waitEvent(newPage, 'load');
      #  // Cleanup.
      #  await newPage.close();
      #});

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
          await browser.wait_for_target(timeout: 0.10) { |target| target.url == server.empty_page }
        end.to raise_error Timeout::Error, "waiting for target failed: 0.1s exceeded"
      end
    end
  end
end
