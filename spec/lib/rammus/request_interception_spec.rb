module Rammus
  RSpec.describe 'Request Interception', browser: true do
    include Promise::Await
    before { @_context = browser.create_context }
    after { @_context.close }
    let(:context) { @_context }
    let!(:page) { context.new_page }

    describe 'Page#set_request_interception' do
      it 'should intercept' do
        page.set_request_interception true
        page.on :request, -> (request) do
          if is_favicon request
            request.continue
            renxt
          end
          expect(request.url).to include 'empty.html'
          expect(request.headers['user-agent']).not_to be_nil
          expect(request.method).to eq 'GET'
          expect(request.post_data).to eq nil
          expect(request.is_navigation_request).to eq true
          expect(request.resource_type).to eq 'document'
          expect(request.frame == page.main_frame).to eq true
          expect(request.frame.url).to eq 'about:blank'
          request.continue
        end
        response = await page.goto server.empty_page
        expect(response.ok?).to eq true
        expect(response.remote_address[:port]).to eq server.port
      end

      it 'should work when POST is redirected with 302' do
        server.set_redirect '/rredirect', '/empty.html'
        await page.goto server.empty_page
        page.set_request_interception true
        page.on :request, -> (request) { request.continue }
        content = <<~HTML
          <form action='/rredirect' method='post'>
            <input type="hidden" id="foo" name="foo" value="FOOBAR">
          </form>
        HTML
        await page.set_content content
        Promise.all(
          page.wait_for_navigation,
          page.query_selector_evaluate_function('form', 'form => form.submit()')
        )
      end

      # @see https://github.com/GoogleChrome/puppeteer/issues/3973
      it 'should work when header manipulation headers with redirect' do
        server.set_redirect '/rrredirect', '/empty.html'
        page.set_request_interception true
        page.on :request, -> (request) do
          headers = request.headers.merge foo: 'bar'
          request.continue headers: headers
        end
        await page.goto server.domain + 'rrredirect'
      end

      it 'should contain referer header' do
        page.set_request_interception true
        requests = []
        page.on :request, -> (request) do
          requests << request unless is_favicon request
          request.continue
        end
        await page.goto server.domain + 'one-style.html'
        expect(requests[1].url).to include '/one-style.css'
        expect(requests[1].headers["referer"]).to include '/one-style.html'
      end

      it 'should properly return navigation response when URL has cookies' do
        # Setup cookie.
        await page.goto server.empty_page
        page.set_cookie name: 'foo', value: 'bar'

        # Setup request interception.
        page.set_request_interception true
        page.on :request, -> (request) { request.continue }
        response = await page.reload
        expect(response.status).to eq 200
      end

      it 'should stop intercepting' do
        page.set_request_interception true
        page.once :request, -> (request) { request.continue }
        await page.goto server.empty_page
        page.set_request_interception false
        await page.goto server.empty_page
      end

      it 'should show custom HTTP headers' do
        page.set_extra_http_headers foo: 'bar'
        page.set_request_interception true
        page.on :request, -> (request) do
          expect(request.headers['foo']).to eq 'bar'
          request.continue
        end
        response = await page.goto server.empty_page
        expect(response.ok?).to eq true
      end

      # @see https://github.com/GoogleChrome/puppeteer/issues/4337
      xit 'should work with redirect inside sync XHR' do
        await page.goto server.empty_page
        server.set_redirect '/logo.png', '/pptr.png'
        page.set_request_interception true
        page.on :request, -> (request) { request.continue }
        status = await page.evaluate_function("async() => {
          const request = new XMLHttpRequest();
          request.open('GET', '/logo.png', false);  // `false` makes the request synchronous
          request.send(null);
          return request.status;
        }")
        expect(status).to eq 200
      end

      it 'should works with customizing referer headers' do
        page.set_extra_http_headers 'referer': server.empty_page
        page.set_request_interception true
        page.on :request, -> (request) do
          expect(request.headers['referer']).to eq server.empty_page
          request.continue
        end
        response = await page.goto server.empty_page
        expect(response.ok?).to eq true
      end

      it 'should be abortable' do
        page.set_request_interception true
        page.on :request, -> (request) do
          if request.url.end_with? '.css'
            request.abort
          else
            request.continue
          end
        end
        failed_requests = 0
        page.on :request_failed, -> (_event) { failed_requests += 1 }
        response = await page.goto server.domain + 'one-style.html'
        expect(response.ok?).to eq true
        expect(response.request.failure).to eq nil
        expect(failed_requests).to eq 1
      end

      it 'should be abortable with custom error codes' do
        page.set_request_interception true
        page.on :request, -> (request) do
          request.abort :internet_disconnected
        end
        failed_request = nil
        page.on :request_failed, -> (request) { failed_request = request }
        await page.goto server.empty_page rescue nil
        expect(failed_request).not_to be_nil
        expect(failed_request.failure[:error_text]).to eq 'net::ERR_INTERNET_DISCONNECTED'
      end

      it 'should send referer' do
        page.set_extra_http_headers referer: 'http://google.com/'
        page.set_request_interception true
        page.on :request, -> (request) { request.continue }
        request, _ = await Promise.all(
          server.wait_for_request('/grid.html'),
          page.goto(server.domain + 'grid.html')
        )
        expect(request.headers['referer']).to eq 'http://google.com/'
      end

      it 'should fail navigation when aborting main resource' do
        page.set_request_interception true
        page.on :request, -> (request) { request.abort }
        expect { await page.goto server.empty_page }
          .to raise_error(/net::ERR_FAILED/)
      end

      it 'should work with redirects' do
        page.set_request_interception true
        requests = []
        page.on :request, -> (request) do
          request.continue
          requests << request
        end
        server.set_redirect '/non-existing-page.html', '/non-existing-page-2.html'
        server.set_redirect '/non-existing-page-2.html', '/non-existing-page-3.html'
        server.set_redirect '/non-existing-page-3.html', '/non-existing-page-4.html'
        server.set_redirect '/non-existing-page-4.html', '/empty.html'
        response = await page.goto server.domain + 'non-existing-page.html'
        expect(response.status).to eq 200
        expect(response.url).to include 'empty.html'
        expect(requests.length).to eq 5
        expect(requests[2].resource_type).to eq 'document'
        # Check redirect chain
        redirect_chain = response.request.redirect_chain
        expect(redirect_chain.length).to eq 4
        expect(redirect_chain[0].url).to include '/non-existing-page.html'
        expect(redirect_chain[2].url).to include '/non-existing-page-3.html'
        redirect_chain.each_with_index do |request, i|
          expect(request.is_navigation_request).to eq true
          expect(request.redirect_chain.find_index request).to eq i
        end
      end

      it 'should work with redirects for subresources' do
        page.set_request_interception true
        requests = []
        page.on :request, -> (request) do
          request.continue
          requests << request unless is_favicon request
        end
        server.set_redirect '/one-style.css', '/two-style.css'
        server.set_redirect '/two-style.css', '/three-style.css'
        server.set_redirect '/three-style.css', '/four-style.css'
        server.set_route('/four-style.css') do |_req, res|
          res.write 'body {box-sizing: border-box; }'
          res.finish
        end

        response = await page.goto server.domain + 'one-style.html'
        expect(response.status).to eq 200
        expect(response.url).to include 'one-style.html'
        expect(requests.length).to eq 5
        expect(requests[0].resource_type).to eq 'document'
        expect(requests[1].resource_type).to eq 'stylesheet'
        # Check redirect chain
        redirect_chain = requests[1].redirect_chain
        expect(redirect_chain.length).to eq 3
        expect(redirect_chain[0].url).to include '/one-style.css'
        expect(redirect_chain[2].url).to include '/three-style.css'
      end

      it 'should be able to abort redirects' do
        page.set_request_interception true
        server.set_redirect '/non-existing.json', '/non-existing-2.json'
        server.set_redirect '/non-existing-2.json', '/simple.html'
        page.on :request, -> (request) do
          if request.url.include? 'non-existing-2'
            request.abort
          else
            request.continue
          end
        end
        await page.goto server.empty_page
        result = await page.evaluate_function("async() => {
          try {
            await fetch('/non-existing.json');
          } catch (e) {
            return e.message;
          }
        }")
        expect(result).to include 'Failed to fetch'
      end

      it 'should work with equal requests' do
        await page.goto server.empty_page
        response_count = 1
        server.set_route '/zzz' do |req, res|
          res.write(response_count * 11)
          response_count += 1
          res.finish
        end
        page.set_request_interception true

        spinner = false
        # Cancel 2nd request.
        page.on :request, -> (request) do
          next request.continue if is_favicon request

          spinner ? request.abort : request.continue
          spinner = !spinner
        end
        results = await page.evaluate_function("() => Promise.all([
          fetch('/zzz').then(response => response.text()).catch(e => 'FAILED'),
          fetch('/zzz').then(response => response.text()).catch(e => 'FAILED'),
          fetch('/zzz').then(response => response.text()).catch(e => 'FAILED'),
        ])")
        expect(results).to eq ['11', 'FAILED', '22']
      end

      it 'should navigate to data_url and fire data_url requests' do
        page.set_request_interception true
        requests = []
        page.on :request, -> (request) do
          requests << request
          request.continue
        end
        data_url = 'data:text/html,<div>yo</div>'
        response = await page.goto data_url
        expect(response.status).to eq 200
        expect(requests.length).to eq 1
        expect(requests[0].url).to eq data_url
      end

      it 'should be able to fetch data_url and fire data_url requests' do
        await page.goto server.empty_page
        page.set_request_interception true
        requests = []
        page.on :request, -> (request) do
          requests << request
          request.continue
        end
        data_url = 'data:text/html,<div>yo</div>'
        text = await page.evaluate_function "url => fetch(url).then(r => r.text())", data_url
        expect(text).to eq '<div>yo</div>'
        expect(requests.length).to eq 1
        expect(requests[0].url).to eq data_url
      end

      it 'should navigate to URL with hash and and fire requests without hash' do
        page.set_request_interception true
        requests = []
        page.on :request, -> (request) do
          requests << request
          request.continue
        end
        response = await page.goto server.empty_page + '#hash'
        expect(response.status).to eq 200
        expect(response.url).to eq server.empty_page
        expect(requests.length).to eq 1
        expect(requests[0].url).to eq server.empty_page
      end

      it 'should work with encoded server' do
        # The requestWillBeSent will report encoded URL, whereas interception will
        # report URL as-is. @see crbug.com/759388
        page.set_request_interception true
        page.on :request, -> (request) { request.continue }
        response = await page.goto server.domain + ' some nonexisting page'
        expect(response.status).to eq 404
      end

      it 'should work with badly encoded server' do
        page.set_request_interception true
        server.set_route('/malformed') { |_req, res| res.finish }
        page.on :request, -> (request) { request.continue }
        response = await page.goto server.domain + 'malformed?rnd=%911'
        expect(response.status).to eq 200
      end

      it 'should work with encoded server - 2' do
        # The requestWillBeSent will report URL as-is, whereas interception will
        # report encoded URL for stylesheet. @see crbug.com/759388
        page.set_request_interception true
        requests = []
        page.on :request, -> (request) do
          request.continue
          requests << request
        end
        response = await page.goto "data:text/html,<link rel=\"stylesheet\" href=\"#{server.domain}/fonts?helvetica|arial\"/>"
        expect(response.status).to eq 200
        expect(requests.length).to eq 2
        expect(requests[1].response.status).to eq 404
      end

      it 'should not throw "Invalid Interception Id" if the request was cancelled' do
        await page.set_content '<iframe></iframe>'
        page.set_request_interception true
        request = nil
        page.on :request, -> (r) { request = r }
        await Promise.all(
          # Wait for request interception.
          wait_event(page, :request),
          page.query_selector_evaluate_function('iframe', "(frame, url) => frame.src = url", server.empty_page)
        )
        # Delete frame to cause request to be canceled.
        page.query_selector_evaluate_function('iframe', "frame => frame.remove()")
        request.continue
      end

      it 'should throw if interception is not enabled' do
        expect do
          page.on :request, -> (request) { request.continue }
          await page.goto server.empty_page
        end.to raise_error(/Request Interception is not enabled/)
      end

      it 'should work with file URLs' do
        page.set_request_interception true
        urls = Set.new
        page.on :request, -> (request) do
          urls << request.url.split('/').last
          request.continue
        end
        file_path = File.expand_path("../../../support/public/one-style.html", __FILE__)
        await page.goto path_to_file_url file_path
        expect(urls.size).to eq 2
        expect(urls).to include 'one-style.html'
        expect(urls).to include 'one-style.css'
      end
    end

    describe 'Request#continue' do
      it 'should work' do
        page.set_request_interception true
        page.on :request, -> (request) { request.continue }
        await page.goto server.empty_page
      end

      it 'should amend HTTP headers' do
        page.set_request_interception true
        page.on :request, -> (request) do
          headers =  request.headers
          headers['FOO'] = 'bar'
          request.continue headers: headers
        end
        await page.goto server.empty_page
        request, _ = await Promise.all(
          server.wait_for_request('/sleep.zzz'),
          page.evaluate_function("() => fetch('/sleep.zzz')")
        )
        expect(request.headers['foo']).to eq 'bar'
      end

      it 'should redirect in a way non-observable to page' do
        page.set_request_interception true
        page.on :request, -> (request) do
          redirect_url = request.url.include?('/empty.html') ? server.domain + 'consolelog.html' : nil
          request.continue url: redirect_url
        end
        console_message = nil
        page.on :console, -> (msg) { console_message = msg }
        await page.goto server.empty_page
        expect(page.url).to eq server.empty_page
        expect(console_message.text).to eq('yellow');
      end

      it 'should amend method' do
        await page.goto server.empty_page

        page.set_request_interception true
        page.on :request, -> (request) do
          request.continue method: 'POST'
        end
        request, _ = await Promise.all(
          server.wait_for_request('/sleep.zzz'),
          page.evaluate_function("() => fetch('/sleep.zzz')")
        )
        expect(request.method).to eq 'POST'
      end

      it 'should amend post data' do
        await page.goto server.empty_page

        page.set_request_interception true
        page.on :request, -> (request) do
          request.continue post_data: 'doggo'
        end
        server_request, _ = await Promise.all(
          server.wait_for_request('/sleep.zzz'),
          page.evaluate_function("() => fetch('/sleep.zzz', { method: 'POST', body: 'birdy' })")
        )
        expect(server_request.post_body).to eq 'doggo'
      end

      it 'should amend both post data and method on navigation' do
        page.set_request_interception true
        page.on :request, -> (request) do
          request.continue method: 'POST', post_data: 'doggo'
        end
        server_request, _ = await Promise.all(
          server.wait_for_request('/empty.html'),
          page.goto(server.empty_page)
        )
        expect(server_request.method).to eq 'POST'
        expect(server_request.post_body).to eq 'doggo'
      end
    end

    describe 'Request#respond' do
      it 'should work' do
        page.set_request_interception true
        page.on :request, -> (request) do
          request.respond status: 201, headers: { foo: 'bar' }, body: 'Yo, page!'
        end
        response = await page.goto server.empty_page
        expect(response.status).to eq 201
        expect(response.headers["foo"]).to eq 'bar'
        expect(await page.evaluate_function("() => document.body.textContent")).to eq 'Yo, page!'
      end

      it 'should work with status code 422' do
        page.set_request_interception true
        page.on :request, -> (request) do
          request.respond status: 422, body: 'Yo, page!'
        end
        response = await page.goto server.empty_page
        expect(response.status).to eq 422
        expect(response.status_text).to eq 'Unprocessable Entity'
        expect(await page.evaluate_function("() => document.body.textContent")).to eq 'Yo, page!'
      end
      it 'should redirect' do
        page.set_request_interception true
        page.on :request, -> (request) do
          unless request.url.include? 'rrredirect'
            request.continue
            next
          end
          request.respond status: 302, headers: { location: server.empty_page }
        end
        response = await page.goto server.domain + 'rrredirect'
        expect(response.request.redirect_chain.length).to eq 1
        expect(response.request.redirect_chain[0].url).to eq server.domain + 'rrredirect'
        expect(response.url).to eq server.empty_page
      end

      it 'should allow mocking binary responses' do
        page.set_request_interception true
        page.on :request, -> (request) do
          path = File.expand_path("../../../support/public/pptr.png", __FILE__)
          request.respond content_type: 'image/png', body: File.read(path)
        end
        page.evaluate_function("PREFIX => {
          const img = document.createElement('img');
          img.src = PREFIX + '/does-not-exist.png';
          document.body.appendChild(img);
          return new Promise(fulfill => img.onload = fulfill);
        }", server.domain)
        img = page.query_selector 'img'
        expect(img.screenshot).to match_screenshot 'mock-binary-response.png'
      end

      it 'should stringify intercepted request response headers' do
        page.set_request_interception true
        page.on :request, -> (request) do
          request.respond status: 200, headers: { 'foo': true }, body: 'Yo, page!'
        end
        response = await page.goto server.empty_page
        expect(response.status).to eq 200
        headers = response.headers
        expect(headers['foo']).to eq 'true'
        expect(await page.evaluate_function("() => document.body.textContent")).to eq 'Yo, page!'
      end
    end

    # @param [String] path
    # @return [String]
    #
    def path_to_file_url(path)
      path_name = path.gsub(/\\/, '/')
      # Windows drive letter must be prefixed with a slash.
      path_name = '/' + path_name unless path_name.start_with? '/'
      "file://#{path_name}"
    end
  end
end
