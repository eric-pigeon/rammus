# frozen_string_literal: true

module Rammus
  RSpec.describe 'Screenshot', browser: true do
    before { @_context = browser.create_context }
    after { @_context.close }
    let(:context) { @_context }
    let!(:page) { context.new_page }

    describe 'Page Events :request' do
      it 'should fire for navigation requests' do
        requests = []
        page.on :request, ->(request) do
          next if is_favicon request

          requests << request
        end
        page.goto(server.empty_page).wait!
        expect(requests.length).to eq 1
      end

      it 'should fire for iframes' do
        requests = []
        page.on :request, ->(request) do
          next if is_favicon request

          requests << request
        end
        page.goto(server.empty_page).wait!
        attach_frame(page, 'frame1', server.empty_page).wait!
        expect(requests.length).to eq 2
      end

      it 'should fire for fetches' do
        requests = []
        page.on :request, ->(request) do
          next if is_favicon request

          requests << request
        end
        page.goto(server.empty_page).wait!
        page.evaluate_function("() => fetch('/empty.html')").wait!
        expect(requests.length).to eq 2
      end
    end

    describe 'Request#frame' do
      it 'should work for main frame navigation request' do
        requests = []
        page.on :request, ->(request) do
          next if is_favicon request

          requests << request
        end
        page.goto(server.empty_page).wait!
        expect(requests.length).to eq 1
        expect(requests[0].frame).to eq page.main_frame
      end

      it 'should work for subframe navigation request' do
        page.goto(server.empty_page).wait!
        requests = []
        page.on :request, ->(request) do
          next if is_favicon request

          requests << request
        end
        attach_frame(page, 'frame1', server.empty_page).wait!
        expect(requests.length).to eq 1
        expect(requests[0].frame).to eq page.frames[1]
      end

      it 'should work for fetch requests' do
        page.goto(server.empty_page).wait!
        requests = []
        page.on :request, ->(request) do
          next if is_favicon request

          requests << request
        end
        page.evaluate_function("() => fetch('/digits/1.png')").wait!
        expect(requests.length).to eq 1
        expect(requests[0].frame).to eq page.main_frame
      end
    end

    describe 'Request#headers' do
      it 'should work' do
        response = page.goto(server.empty_page).value!
        expect(response.request.headers['user-agent']).to include 'Chrome'
      end
    end

    describe 'Response#headers' do
      it 'should work' do
        server.set_route '/empty.html' do |_req, res|
          res.header['foo'] = 'bar'
          res.finish
        end
        response = page.goto(server.empty_page).value!
        expect(response.headers['foo']).to eq 'bar'
      end
    end

    describe 'Response#from_cache' do
      it 'should return |false| for non-cached content' do
        response = page.goto(server.empty_page).value!
        expect(response.from_cache).to eq false
      end

      it 'should work' do
        responses = {}
        page.on :response, ->(request) do
          next if is_favicon request

          responses[request.url.split('/').pop] = request
        end

        # Load and re-load to make sure it's cached.
        page.goto(server.domain + 'cached/one-style.html').wait!
        page.reload.wait!

        expect(responses.size).to eq 2
        expect(responses['one-style.css'].status).to eq 200
        expect(responses['one-style.css'].from_cache).to eq true
        expect(responses['one-style.html'].status).to eq 304
        expect(responses['one-style.html'].from_cache).to eq false
      end
    end

    describe 'Response#from_service_worker' do
      it 'should return |false| for non-service-worker content' do
        response = page.goto(server.empty_page).value!
        expect(response.from_service_worker).to eq false
      end

      it 'Response#from_service_worker' do
        responses = {}
        page.on :response, ->(request) do
          next if is_favicon request

          responses[request.url.split('/').pop] = request
        end

        # Load and re-load to make sure serviceworker is installed and running.
        page.goto(server.domain + 'serviceworkers/fetch/sw.html', wait_until: :networkidle2).wait!
        page.evaluate_function('async() => await window.activationPromise').wait!
        page.reload.wait!

        expect(responses.size).to eq 2
        expect(responses['sw.html'].status).to eq 200
        expect(responses['sw.html'].from_service_worker).to eq true
        expect(responses['style.css'].status).to eq 200
        expect(responses['style.css'].from_service_worker).to eq true
      end
    end

    describe 'Request#post_data' do
      it 'should work' do
        page.goto(server.empty_page).wait!
        request = nil
        page.on :request, ->(r) { request = r }
        page.evaluate_function("() => fetch('./post', { method: 'POST', body: JSON.stringify({foo: 'bar'})})").wait!
        expect(request).not_to be_nil
        expect(request.post_data).to eq '{"foo":"bar"}'
      end

      it 'should be |undefined| when there is no post data' do
        response = page.goto(server.empty_page).value!
        expect(response.request.post_data).to eq nil
      end
    end

    describe 'Response#text' do
      it 'should work' do
        response = page.goto(server.domain + 'simple.json').value!
        expect(response.text.value!).to eq "{\"foo\": \"bar\"}\n"
      end

      it 'should return uncompressed text' do
        server.enable_gzip '/simple.json'
        response = page.goto(server.domain + 'simple.json').value!
        expect(response.headers['content-encoding']).to eq 'gzip'
        expect(response.text.value!).to eq "{\"foo\": \"bar\"}\n"
      end

      it 'should throw when requesting body of redirected response' do
        server.set_redirect '/foo.html', '/empty.html'
        response = page.goto(server.domain + "foo.html").value!
        redirect_chain = response.request.redirect_chain
        expect(redirect_chain.length).to eq 1
        redirected = redirect_chain[0].response
        expect(redirected.status).to eq 302

        expect { redirected.text.value! }
          .to raise_error(/Response body is unavailable for redirect responses/)
      end

      it 'should wait until response completes' do
        page.goto(server.empty_page).wait!
        # Setup server to trap request.
        server_response = nil
        server.set_route '/get' do |_req, res|
          # In Firefox, |fetch| will be hanging until it receives |Content-Type| header
          # from server.
          res.header['Content-Type'] = 'text/plain; charset=utf-8'
          server_response, rack_response = res.set_chunked_response!
          server_response << "hello "
          rack_response
        end
        # Setup page to trap response.
        request_finished = false
        page.on :request_Finished, ->(r) { request_finished ||= r.url.include?('/get') }
        # send request and wait for server response
        page_response, _ = Concurrent::Promises.zip(
          page.wait_for_response { |r| !is_favicon r.request },
          page.evaluate_function("() => fetch('./get', { method: 'GET'})"),
          server.wait_for_request('/get')
        ).value!

        expect(server_response).not_to be_nil
        expect(page_response).not_to be_nil
        expect(page_response.status).to eq 200
        expect(request_finished).to eq false

        response_text = page_response.text
        # Write part of the response
        server_response << "wor"
        # Finish response
        server_response << "ld!"
        server_response.finish
        expect(response_text.value!).to eq 'hello world!'
      end
    end

    describe 'Response#json' do
      it 'should work' do
        response = page.goto(server.domain + 'simple.json').value!
        expect(response.json.value!).to eq 'foo' => 'bar'
      end
    end

    describe 'Response#buffer' do
      it 'should work' do
        response = page.goto(server.domain + 'pptr.png').value!
        path = File.expand_path("../../support/public/pptr.png", File.dirname(__FILE__))
        image_buffer = IO.binread(path)
        response_buffer = response.buffer.value!
        expect(response_buffer).to eq image_buffer
      end

      it 'should work with compression' do
        server.enable_gzip '/pptr.png'
        response = page.goto(server.domain + 'pptr.png').value!
        path = File.expand_path("../../support/public/pptr.png", File.dirname(__FILE__))
        image_buffer = IO.binread(path)
        response_buffer = response.buffer.value!
        expect(response_buffer).to eq image_buffer
      end
    end

    describe 'Response#status_text' do
      it 'should work' do
        response = page.goto(server.domain + 'empty.html').value!
        expect(response.status_text).to eq 'OK'
      end
    end

    describe 'Network Events' do
      it 'Page.Events.Request' do
        requests = []
        page.on :request, ->(request) { requests << request }
        page.goto(server.empty_page).wait!
        expect(requests.length).to eq 1
        expect(requests[0].url).to eq server.empty_page
        expect(requests[0].resource_type).to eq 'document'
        expect(requests[0].method).to eq 'GET'
        expect(requests[0].response).not_to be_nil
        expect(requests[0].frame == page.main_frame).to eq true
        expect(requests[0].frame.url).to eq server.empty_page
      end

      it 'Page.Events.Response' do
        responses = []
        page.on :response, ->(response) { responses << response }
        page.goto(server.empty_page).wait!
        expect(responses.length).to eq 1
        expect(responses[0].url).to eq server.empty_page
        expect(responses[0].status).to eq 200
        expect(responses[0].ok?).to eq true
        expect(responses[0].request).not_to be_nil
        remote_address = responses[0].remote_address
        # Either IPv6 or IPv4, depending on environment.
        expect(remote_address[:ip].include?('::1') || remote_address[:ip] == '127.0.0.1').to eq true
        expect(remote_address[:port]).to eq server.port
      end

      it 'Page.Events.RequestFailed' do
        page.set_request_interception true
        page.on :request, ->(request) do
          if request.url.end_with? 'css'
            request.abort
          else
            request.continue
          end
        end
        failed_requests = []
        page.on :request_failed, ->(request) { failed_requests << request }
        page.goto(server.domain + 'one-style.html').wait!
        expect(failed_requests.length).to eq 1
        expect(failed_requests[0].url).to include 'one-style.css'
        expect(failed_requests[0].response).to eq nil
        expect(failed_requests[0].resource_type).to eq 'stylesheet'
        expect(failed_requests[0].failure[:error_text]).to eq 'net::ERR_FAILED'
        expect(failed_requests[0].frame).not_to be_nil
      end

      it 'Page.Events.RequestFinished' do
        requests = []
        page.on :request_finished, ->(request) { requests << request }
        page.goto(server.empty_page).wait!
        expect(requests.length).to eq 1
        expect(requests[0].url).to eq server.empty_page
        expect(requests[0].response).not_to be_nil
        expect(requests[0].frame == page.main_frame).to eq true
        expect(requests[0].frame.url).to eq server.empty_page
      end

      it 'should fire events in proper order' do
        events = []
        page.on :request, ->(_request) { events << 'request' }
        page.on :response, ->(_response) { events << 'response' }
        page.on :request_finished, ->(_request) { events << 'requestfinished' }
        page.goto(server.empty_page).wait!
        expect(events).to eq ['request', 'response', 'requestfinished']
      end

      it 'should support redirects' do
        events = []
        page.on :request, ->(request) { events << "#{request.method} #{request.url}" }
        page.on :response, ->(response) { events << "#{response.status} #{response.url}" }
        page.on :request_finished, ->(request) { events << "DONE #{request.url}" }
        page.on :request_failed, ->(request) { events << "FAIL #{request.url}" }
        server.set_redirect '/foo.html', '/empty.html'
        foo_url = server.domain + 'foo.html'
        response = page.goto(foo_url).value!
        expect(events).to eq [
          "GET #{foo_url}",
          "302 #{foo_url}",
          "DONE #{foo_url}",
          "GET #{server.empty_page}",
          "200 #{server.empty_page}",
          "DONE #{server.empty_page}"
        ]

        # Check redirect chain
        redirect_chain = response.request.redirect_chain
        expect(redirect_chain.length).to eq 1
        expect(redirect_chain[0].url).to include '/foo.html'
        expect(redirect_chain[0].response.remote_address[:port]).to eq server.port
      end
    end

    describe 'Request#is_navigation_Request' do
      it 'should work' do
        requests = {}
        page.on :request, ->(request) { requests[request.url.split('/').pop] = request }
        server.set_redirect '/rrredirect', '/frames/one-frame.html'
        page.goto(server.domain + 'rrredirect').wait!
        expect(requests['rrredirect'].is_navigation_request).to eq true
        expect(requests['one-frame.html'].is_navigation_request).to eq true
        expect(requests['frame.html'].is_navigation_request).to eq true
        expect(requests['script.js'].is_navigation_request).to eq false
        expect(requests['style.css'].is_navigation_request).to eq false
      end

      it 'should work with request interception' do
        requests = {}
        page.on :request, ->(request) do
          requests[request.url.split('/').pop] = request
          request.continue
        end
        page.set_request_interception true
        server.set_redirect '/rrredirect', '/frames/one-frame.html'
        page.goto(server.domain + 'rrredirect').wait!
        expect(requests['rrredirect'].is_navigation_request).to eq true
        expect(requests['one-frame.html'].is_navigation_request).to eq true
        expect(requests['frame.html'].is_navigation_request).to eq true
        expect(requests['script.js'].is_navigation_request).to eq false
        expect(requests['style.css'].is_navigation_request).to eq false
      end

      it 'should work when navigating to image' do
        requests = []
        page.on :request, ->(request) { requests << request }
        page.goto(server.domain + 'pptr.png').wait!
        expect(requests[0].is_navigation_request).to eq true
      end
    end

    describe 'Page#set_extra_http_headers' do
      it 'should work' do
        page.set_extra_http_headers foo: 'bar'
        request, _ = Concurrent::Promises.zip(
          server.wait_for_request('/empty.html'),
          page.goto(server.empty_page)
        ).value!
        expect(request.headers['foo']).to eq 'bar'
      end

      it 'should throw for non-string header values' do
        expect { page.set_extra_http_headers 'foo' => 1 }
          .to raise_error "Expected value of header 'foo' to be String, but 'Integer' is found."
      end
    end

    describe 'Page#authenticate' do
      it 'should work' do
        server.set_auth '/empty.html', 'user', 'pass'
        response = page.goto(server.empty_page).value!
        expect(response.status).to eq 401
        page.authenticate username: 'user', password: 'pass'
        response = page.reload.value!
        expect(response.status).to eq 200
      end

      it 'should fail if wrong credentials' do
        server.set_auth '/empty.html', 'user2', 'pass2'
        page.authenticate username: 'foo', password: 'bar'
        response = page.goto(server.empty_page).value!
        expect(response.status).to eq 401
      end

      it 'should allow disable authentication' do
        server.set_auth '/empty.html', 'user3', 'pass3'
        page.authenticate username: 'user3', password: 'pass3'
        response = page.goto(server.empty_page).value!
        expect(response.status).to eq 200

        page.authenticate
        # Navigate to a different origin to bust Chrome's credential caching.
        response = page.goto(server.cross_process_domain + 'empty.html').value!
        expect(response.status).to eq 401
      end
    end
  end
end
