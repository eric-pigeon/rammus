module Chromiebara
  RSpec.describe 'Navigation', browser: true do
    include Promise::Await
    before { @_context = browser.create_context }
    after { @_context.close }
    let(:context) { @_context }
    let!(:page) { context.new_page }

    describe 'Page.goto' do
      it 'should work' do
        await page.goto server.empty_page
        expect(page.url).to eq server.empty_page
      end

      it 'should work with anchor navigation' do
        await page.goto server.empty_page
        expect(page.url).to eq server.empty_page
        await page.goto server.empty_page + '#foo'
        expect(page.url).to eq server.empty_page + '#foo'
        await page.goto server.empty_page + '#bar'
        expect(page.url).to eq server.empty_page + '#bar'
      end

      it 'should work with redirects' do
        server.set_redirect '/redirect/1.html', '/redirect/2.html'
        server.set_redirect '/redirect/2.html', '/empty.html'
        await page.goto server.domain + 'redirect/1.html'
        expect(page.url).to eq server.empty_page
      end

      it 'should navigate to about:blank' do
        response = await page.goto 'about:blank'
        expect(response).to eq nil
      end

      it 'should return response when page changes its URL after load' do
        response = await page.goto server.domain + 'historyapi.html'
        expect(response.status).to eq 200
      end

      it 'should work with subframes return 204' do
        server.set_route '/frames/frame.html' do |req, res|
          res.status = 204
          res.finish
        end
        await page.goto server.domain + 'frames/one-frame.html'
      end

      it 'should fail when server returns 204' do
        server.set_route '/empty.html' do |req, res|
          res.status = 204
          res.finish
        end
        expect { await page.goto server.empty_page }.to raise_error(/net::ERR_ABORTED/)
      end

      it 'should navigate to empty page with domcontentloaded' do
        response = await page.goto server.empty_page, wait_until: :domcontentloaded
        expect(response.status).to eq 200
      end

      it 'should work when page calls history API in beforeunload' do
        await page.goto server.empty_page
        await page.evaluate_function "() => {
          window.addEventListener('beforeunload', () => history.replaceState(null, 'initial', window.location.href), false);
        }"
        response = await page.goto server.domain + 'grid.html'
        expect(response.status).to eq 200
      end

      it 'should navigate to empty page with networkidle0' do
        response = await page.goto server.empty_page, wait_until: :networkidle0
        expect(response.status).to eq 200
      end

      it 'should navigate to empty page with networkidle2' do
        response = await page.goto server.empty_page, wait_until: :networkidle2
        expect(response.status).to eq 200
      end

      it 'should fail when navigating to bad url' do
        expect { await page.goto('asdfasdf') }.to raise_error(/Cannot navigate to invalid URL/)
      end

      xit 'should fail when navigating to bad SSL' do
        # TODO
        # Make sure that network events do not emit 'undefined'.
        # @see https://crbug.com/750469
        #page.on('request', request => expect(request).to eqTruthy());
        #page.on('requestfinished', request => expect(request).to eqTruthy());
        #page.on('requestfailed', request => expect(request).to eqTruthy());
        #let error = null;
        #await page.goto(httpsServer.empty_page).catch(e => error = e);
        #if (CHROME)
        #  expect(error.message).toContain('net::ERR_CERT_AUTHORITY_INVALID');
        #else
        #  expect(error.message).toContain('SSL_ERROR_UNKNOWN');
      end

      xit 'should fail when navigating to bad SSL after redirects' do
        # TODO
        #server.setRedirect('/redirect/1.html', '/redirect/2.html');
        #server.setRedirect('/redirect/2.html', '/empty.html');
        #let error = null;
        #await page.goto(httpsServer.domain + '/redirect/1.html').catch(e => error = e);
        #if (CHROME)
        #  expect(error.message).toContain('net::ERR_CERT_AUTHORITY_INVALID');
        #else
        #  expect(error.message).toContain('SSL_ERROR_UNKNOWN');
      end

      it 'should fail when main resources failed to load' do
        expect { await page.goto 'http://localhost:44123/non-existing-url' }
          .to raise_error(/net::ERR_CONNECTION_REFUSED/)
      end

      it 'should fail when exceeding maximum navigation timeout' do
        # Hang for request to the empty.html
        finish_response = nil
        server.set_route '/empty.html' do |_req, res|
          await Promise.new { |resolve, _reject| finish_response = resolve }
            .then { res.finish }
        end
        expect { await page.goto server.domain + 'empty.html', timeout: 0.1 }
          .to raise_error(Timeout::Error, /Navigation Timeout Exceeded: 0.1s/)
        finish_response.(nil)
      end

      it 'should fail when exceeding default maximum navigation timeout' do
        # Hang for request to the empty.html
        finish_response = nil
        server.set_route '/empty.html' do |_req, res|
          await Promise.new { |resolve, _reject| finish_response = resolve }
            .then { res.finish }
        end
        page.set_default_navigation_timeout 0.1
        expect { await page.goto server.domain + 'empty.html' }
          .to raise_error(Timeout::Error, /Navigation Timeout Exceeded: 0.1s/)
        finish_response.(nil)
      end

      it 'should fail when exceeding default maximum timeout' do
        # Hang for request to the empty.html
        finish_response = nil
        server.set_route '/empty.html' do |_req, res|
          await Promise.new { |resolve, _reject| finish_response = resolve }
            .then { res.finish }
        end
        page.set_default_timeout 0.1
        expect { await page.goto server.domain + 'empty.html' }
          .to raise_error(Timeout::Error, /Navigation Timeout Exceeded: 0.1s/)
        finish_response.(nil)
      end

      it 'should prioritize default navigation timeout over default timeout' do
        # Hang for request to the empty.html
        finish_response = nil
        server.set_route '/empty.html' do |_req, res|
          await Promise.new { |resolve, _reject| finish_response = resolve }
            .then { res.finish }
        end
        page.set_default_timeout 0
        page.set_default_navigation_timeout 0.1
        expect { await page.goto server.domain + 'empty.html' }
          .to raise_error(Timeout::Error, /Navigation Timeout Exceeded: 0.1s/)
        finish_response.(nil)
      end

      it 'should disable timeout when its set to 0' do
        loaded = false
        page.once :load, -> (_event) { loaded = true }
        await page.goto server.domain + 'grid.html', timeout: 0, wait_until: [:load]
        expect(loaded).to eq true
      end

      it 'should work when navigating to valid url' do
        response = await page.goto server.empty_page
        expect(response.ok?).to eq true
      end

      it 'should work when navigating to data url' do
        response = await page.goto 'data:text/html,hello'
        expect(response.ok?).to eq true
      end

      it 'should work when navigating to 404' do
        response = await page.goto server.domain + 'not-found'
        expect(response.ok?).to eq false
        expect(response.status).to eq 404
      end

      it 'should return last response in redirect chain' do
        server.set_redirect '/redirect/1.html', '/redirect/2.html'
        server.set_redirect '/redirect/2.html', '/redirect/3.html'
        server.set_redirect '/redirect/3.html', server.empty_page
        response = await page.goto server.domain + 'redirect/1.html'
        expect(response.ok?).to eq true
        expect(response.url).to eq server.empty_page
      end

      xit 'should wait for network idle to succeed navigation' do
        # TODO
        #responses = []
        ## Hold on to a bunch of requests without answering.
        #server.setRoute('/fetch-request-a.js', (req, res) => responses.push(res));
        #server.setRoute('/fetch-request-b.js', (req, res) => responses.push(res));
        #server.setRoute('/fetch-request-c.js', (req, res) => responses.push(res));
        #server.setRoute('/fetch-request-d.js', (req, res) => responses.push(res));
        #initialFetchResourcesRequested = Promise.all([
        #  server.waitForRequest('/fetch-request-a.js'),
        #  server.waitForRequest('/fetch-request-b.js'),
        #  server.waitForRequest('/fetch-request-c.js'),
        #]);
        #secondFetchResourceRequested = server.waitForRequest('/fetch-request-d.js');

        ## Navigate to a page which loads immediately and then does a bunch of
        ## requests via javascript's fetch method.
        #navigationPromise = await page.goto(server.domain + '/networkidle.html', {
        #  waitUntil: 'networkidle0',
        #end
        ## Track when the navigation gets completed.
        #let navigationFinished = false;
        #navigationPromise.then(() => navigationFinished = true);

        ## Wait for the page's 'load' event.
        #await new Promise(fulfill => page.once('load', fulfill));
        #expect(navigationFinished).to eq(false);

        ## Wait for the initial three resources to be requested.
        #await initialFetchResourcesRequested;

        ## Expect navigation still to be not finished.
        #expect(navigationFinished).to eq(false);

        ## Respond to initial requests.
        #for (response of responses) {
        #  response.statusCode = 404;
        #  response.end(`File not found`);
        #}

        ## Reset responses array
        #responses = [];

        ## Wait for the second round to be requested.
        #await secondFetchResourceRequested;
        ## Expect navigation still to be not finished.
        #expect(navigationFinished).to eq(false);

        ## Respond to requests.
        #for (response of responses) {
        #  response.statusCode = 404;
        #  response.end(`File not found`);
        #}

        #response = await navigationPromise;
        ## Expect navigation to succeed.
        #expect(response.ok()).to eq(true);
      end

      it 'should navigate to dataURL and fire dataURL requests' do
        requests = []
        page.on :request, -> (request) do
          next if is_favicon request
          requests << request
        end
        data_url = 'data:text/html,<div>yo</div>'
        response = await page.goto data_url
        expect(response.status).to eq 200
        expect(requests.length).to eq 1
        expect(requests[0].url).to eq data_url
      end

      it 'should navigate to URL with hash and fire requests without hash' do
        requests = []
        page.on :request, -> (request) do
          next if is_favicon request
          requests << request
        end
        response = await page.goto server.empty_page + '#hash'
        expect(response.status).to eq 200
        expect(response.url).to eq server.empty_page
        expect(requests.length).to eq 1
        expect(requests[0].url).to eq server.empty_page
      end

      it 'should work with self requesting page' do
        response = await page.goto server.domain + 'self-request.html'
        expect(response.status).to eq 200
        expect(response.url).to include 'self-request.html'
      end

      xit 'should fail when navigating and show the url at the error message' do
        # TODO
        #url = httpsServer.domain + '/redirect/1.html';
        #let error = null;
        #try {
        #  await page.goto(url);
        #} catch (e) {
        #  error = e;
        #}
        #expect(error.message).toContain(url);
      end

      it 'should send referer' do
        request1, request2 = await Promise.all(
          server.wait_for_request('/grid.html'),
          server.wait_for_request('/digits/1.png'),
          page.goto(server.domain + 'grid.html', referer: 'http://google.com/')
        )
        expect(request1.headers['referer']).to eq 'http://google.com/'
        # Make sure subresources do not inherit referer.
        expect(request2.headers['referer']).to eq server.domain + 'grid.html'
      end
    end

    describe 'Page#wait_for_navigation' do
      it 'should work' do
        await page.goto server.empty_page
        response, _ = await Promise.all(
          page.wait_for_navigation,
          page.evaluate_function('url => window.location.href = url', server.domain + 'grid.html')
        )
        expect(response.ok?).to eq true
        expect(response.url).to include 'grid.html'
      end

      it 'should work with both domcontentloaded and load' do
        response = nil
        server.set_route('/one-style.css') { |req, res| response = res }

        dom_content_loaded_promise = page.wait_for_navigation wait_until: :domcontentloaded

        both_fired = false
        both_fired_promise = page.wait_for_navigation(wait_until: [:load, :domcontentloaded]).then do
          both_fired = true
        end

        request_promise = server.wait_for_request '/one-style.css'

        navigation_promise = page.goto(server.domain + 'one-style.html')

        await request_promise
        await dom_content_loaded_promise

        expect(both_fired).to eq(false)

        response.finish
        await both_fired_promise
        await navigation_promise
      end

      it 'should work with clicking on anchor links' do
        await page.goto server.empty_page
        await page.set_content "<a href='#foobar'>foobar</a>"
        response, _ = await Promise.all(
          page.wait_for_navigation,
          page.click('a')
        )
        expect(response).to eq nil
        expect(page.url).to eq server.empty_page + '#foobar'
      end

      it 'should work with history.pushState()' do
        await page.goto server.empty_page
        await page.set_content("
          <a onclick='javascript:pushState()'>SPA</a>
          <script>
            function pushState() { history.pushState({}, '', 'wow.html') }
          </script>
        ")
        response, _ = await Promise.all(
          page.wait_for_navigation,
          page.click('a')
        )
        expect(response).to eq nil
        expect(page.url).to eq server.domain + 'wow.html'
      end

      it 'should work with history.replaceState()' do
        await page.goto server.empty_page
        await page.set_content("
          <a onclick='javascript:replaceState()'>SPA</a>
          <script>
            function replaceState() { history.replaceState({}, '', '/replaced.html') }
          </script>
        ")
        response, _ = await Promise.all(
          page.wait_for_navigation,
          page.click('a')
        )
        expect(response).to eq nil
        expect(page.url).to eq server.domain + 'replaced.html'
      end

      it 'should work with DOM history.back()/history.forward()' do
        await page.goto server.empty_page
        await page.set_content("
          <a id=back onclick='javascript:goBack()'>back</a>
          <a id=forward onclick='javascript:goForward()'>forward</a>
          <script>
            function goBack() { history.back(); }
            function goForward() { history.forward(); }
            history.pushState({}, '', '/first.html');
            history.pushState({}, '', '/second.html');
          </script>
        ")
        expect(page.url).to eq server.domain + 'second.html'
        back_response, _  = await Promise.all(
          page.wait_for_navigation,
          page.click('a#back')
        )
        expect(back_response).to eq nil
        expect(page.url).to eq server.domain + 'first.html'
        forward_response, _ = await Promise.all(
          page.wait_for_navigation,
          page.click('a#forward'),
        )
        expect(forward_response).to eq nil
        expect(page.url).to eq server.domain + 'second.html'
      end

      it 'should work when subframe issues window.stop()' do
        finish_response = server.hang_route '/frames/style.css'

        await Promise.all(
          wait_event(page, :frame_attached).then do |frame|
            await(wait_event(page, :frame_navigated) { |f| f == frame })
            frame.evaluate_function "() => window.stop()"
          end,
          page.goto(server.domain + 'frames/one-frame.html')
        )
        finish_response.(nil)
      end
    end

    describe 'Page#go_back' do
      it 'should work' do
        await page.goto server.empty_page
        await page.goto server.domain + 'grid.html'

        response = page.go_back
        expect(response.ok?).to eq true
        expect(response.url).to include server.empty_page

        response = page.go_forward
        expect(response.ok?).to eq true
        expect(response.url).to include '/grid.html'

        response = page.go_forward
        expect(response).to eq nil
      end

      it 'should work with HistoryAPI' do
        await page.goto server.empty_page
        await page.evaluate_function "() => {
          history.pushState({}, '', '/first.html');
          history.pushState({}, '', '/second.html');
        }"
        browser.wait_for_target { |target| target.url == server.domain + 'second.html' }
        expect(page.url).to eq server.domain + 'second.html'

        page.go_back
        expect(page.url).to eq server.domain + 'first.html'
        page.go_back
        expect(page.url).to eq server.empty_page
        page.go_forward
        expect(page.url).to eq server.domain + 'first.html'
      end
    end

    describe 'Frame#goto' do
      it 'should navigate subframes' do
        await page.goto server.domain + 'frames/one-frame.html'
        expect(page.frames[0].url).to include '/frames/one-frame.html'
        expect(page.frames[1].url).to include '/frames/frame.html'

        response = await page.frames[1].goto server.empty_page
        expect(response.ok?).to eq true
        expect(response.frame).to eq page.frames[1]
      end

      it 'should reject when frame detaches' do
        await page.goto server.domain + 'frames/one-frame.html'

        finish_response = nil
        server.set_route '/empty.html' do |_req, res|
          await Promise.new { |resolve, _reject| finish_response = resolve }
            .then { res.finish }
        end

        expect do
          await Promise.all(
            server.wait_for_request('/empty.html').then do
              page.query_selector_evaluate_function('iframe', 'frame => frame.remove()')
            end,
            page.frames[1].goto(server.empty_page)
          )
        end.to raise_error 'Navigating frame was detached'

        finish_response.(nil)
      end

      it 'should return matching responses' do
        # Disable cache: otherwise, chromium will cache similar requests.
        page.set_cache_enabled false
        await page.goto server.empty_page
        # Attach three frames.
        frames = await Promise.all(
          attach_frame(page, 'frame1', server.empty_page),
          attach_frame(page, 'frame2', server.empty_page),
          attach_frame(page, 'frame3', server.empty_page),
        )
        # Navigate all frames to the same URL.
        server_responses = []
        server.set_route '/one-style.html' do |req, res|
          promise, resolve, _reject = Promise.create
          server_responses << resolve
          await promise.then { |val| res.write(val); res.finish }
        end

        navigations = []
        3.times do |i|
          navigations << (frames[i].goto server.domain + 'one-style.html')
          await server.wait_for_request '/one-style.html'
        end

        # Respond from server out-of-order.
        server_responses.zip(navigations, frames, ['AAA', 'BBB', 'CCC']).each do |server, navigation, frame, text|
          server.call text
          response = await navigation
          expect(response.frame).to eq frame
          expect(await response.text).to eq text
        end
      end
    end

    describe 'Frame.wait_for_navigation' do
      it 'should work' do
        await page.goto server.domain + '/frames/one-frame.html'
        frame = page.frames[1]
        response, _ = await Promise.all(
          frame.wait_for_navigation,
          frame.evaluate_function('url => window.location.href = url', server.domain + 'grid.html')
        )
        expect(response.ok?).to eq true
        expect(response.url).to include 'grid.html'
        expect(response.frame).to eq frame
        expect(page.url).to include '/frames/one-frame.html'
      end

      it 'should fail when frame detaches' do
        await page.goto server.domain + 'frames/one-frame.html'
        frame = page.frames[1]

        finish_response = nil
        server.set_route '/empty.html' do |_req, res|
          await Promise.new { |resolve, _reject| finish_response = resolve }
            .then { res.finish }
        end

        navigation_promise = frame.wait_for_navigation.catch { |error| error }
        await Promise.all(
          server.wait_for_request('/empty.html'),
          frame.evaluate_function("() => window.location = '/empty.html'")
        )
        page.query_selector_evaluate_function('iframe', "frame => frame.remove()")
        expect((await navigation_promise).message).to eq 'Navigating frame was detached'
        finish_response.(nil)
      end
    end

    describe 'Page.reload' do
      it 'should work' do
        await page.goto server.empty_page
        await page.evaluate_function'() => window._foo = 10'
        await page.reload
        expect(await page.evaluate_function '() => window._foo').to eq(nil)
      end
    end
  end
end
