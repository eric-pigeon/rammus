# frozen_string_literal: true

module Rammus
  RSpec.describe Page, page: true do
    describe '#close' do
      it 'should reject all promises when page is closed' do
        new_page = context.new_page
        error = nil
        Concurrent::Promises.zip(
          new_page.evaluate_function("() => new Promise(r => {})").rescue { |e| error = e },
          new_page.close
        ).wait!
        expect(error.message).to include 'Protocol error'
      end

      it 'should not be visible in browser.pages' do
        new_page = browser.new_page
        expect(browser.pages).to include new_page

        new_page.close.wait!
        expect(browser.pages).not_to include new_page
      end

      it 'should run beforeunload if asked for' do
        new_page = context.new_page
        new_page.goto(server.domain + 'beforeunload.html').wait!
        # We have to interact with a page so that 'beforeunload' handlers
        # fire.
        new_page.click 'body'
        new_page.close run_before_unload: true
        dialog = wait_event(new_page, :dialog).value!
        expect(dialog.type).to eq :beforeunload
        expect(dialog.default_value).to eq ''
        expect(dialog.message).to eq ''
        dialog.accept
      end

      it 'should *not* run beforeunload by default' do
        new_page = context.new_page
        new_page.goto(server.domain + 'beforeunload.html').wait!
        # We have to interact with a page so that 'beforeunload' handlers
        # fire.
        new_page.click 'body'
        new_page.close.wait!
      end

      it 'should set the page close state' do
        new_page = context.new_page
        expect(new_page.closed?).to eq false
        new_page.close.wait!
        expect(new_page.closed?).to eq true
      end

      it 'should terminate network waiters' do
        new_page = context.new_page

        results = Concurrent::Promises.zip(
          new_page.wait_for_request(server.empty_page).rescue { |e| e },
          new_page.wait_for_response(server.empty_page).rescue { |e| e },
          new_page.close
        ).value!

        results.take(2).each do |result|
          expect(result.message).to include 'Target closed'
          expect(result.message).not_to include 'Timeout'
        end
      end
    end

    describe 'Page.Events.Load' do
      it 'should fire when expected' do
        Concurrent::Promises.zip(
          wait_event(page, :load),
          page.goto('about:blank')
        ).wait!
      end
    end

    describe 'Page.Events.error' do
      it 'should throw when page crashes' do
        skip "Travis version of chrome doesn't send Inspector.targetCrashed on chrome://crash" if ENV["TRAVIS"] == "true"
        error = nil
        page.on :error, ->(err) { error = err }
        Concurrent::Promises.zip(
          wait_event(page, :error),
          page.goto('chrome://crash').rescue { |_err| }
        ).wait!
        expect(error.message).to eq 'Page crashed!'
      end
    end

    describe 'Page.Events.Popup' do
      it 'should work' do
        popup, _ = Concurrent::Promises.zip(
          Concurrent::Promises.resolvable_future.tap { |future| page.once :popup, future.method(:fulfill) },
          page.evaluate_function("() => window.open('about:blank')")
        ).value!
        expect(page.evaluate_function("() => !!window.opener").value!).to eq false
        expect(popup.evaluate_function("() => !!window.opener").value!).to eq true
      end

      it 'should work with noopener' do
        popup, _ = Concurrent::Promises.zip(
          Concurrent::Promises.resolvable_future.tap { |future| page.once :popup, future.method(:fulfill) },
          page.evaluate_function("() => window.open('about:blank', null, 'noopener')")
        ).value!
        expect(page.evaluate_function("() => !!window.opener").value!).to eq false
        expect(popup.evaluate_function("() => !!window.opener").value!).to eq false
      end

      it 'should work with clicking target=_blank' do
        page.goto(server.empty_page).wait!
        page.set_content('<a target=_blank href="/one-style.html">yo</a>').wait!
        popup, _ = Concurrent::Promises.zip(
          Concurrent::Promises.resolvable_future.tap { |future| page.once :popup, future.method(:fulfill) },
          Concurrent::Promises.future { page.click('a') }
        ).value!
        expect(page.evaluate_function("() => !!window.opener").value!).to eq false
        expect(popup.evaluate_function("() => !!window.opener").value!).to eq true
      end

      it 'should work with fake-clicking target=_blank and rel=noopener' do
        page.goto(server.empty_page).wait!
        page.set_content('<a target=_blank rel=noopener href="/one-style.html">yo</a>').value!
        popup, _ = Concurrent::Promises.zip(
          Concurrent::Promises.resolvable_future.tap { |future| page.once :popup, future.method(:fulfill) },
          page.query_selector_evaluate_function('a', 'a => a.click()')
        ).value!
        expect(page.evaluate_function("() => !!window.opener").value!).to eq false
        expect(popup.evaluate_function("() => !!window.opener").value!).to eq false
      end

      it 'should work with clicking target=_blank and rel=noopener' do
        page.goto(server.empty_page).wait!
        page.set_content('<a target=_blank rel=noopener href="/one-style.html">yo</a>').wait!
        popup, _ = Concurrent::Promises.zip(
          Concurrent::Promises.resolvable_future.tap { |future| page.once :popup, future.method(:fulfill) },
          Concurrent::Promises.future { page.click('a') }
        ).value!
        expect(page.evaluate_function("() => !!window.opener").value!).to eq false
        expect(popup.evaluate_function("() => !!window.opener").value!).to eq false
      end
    end

    describe 'BrowserContext#override_permissions' do
      def get_permission(page, name)
        page
          .evaluate_function("name => navigator.permissions.query({name}).then(result => result.state)", name)
          .value!
      end

      it 'should be prompt by default' do
        page.goto(server.empty_page).wait!
        expect(get_permission(page, 'geolocation')).to eq 'prompt'
      end

      it 'should deny permission when not listed' do
        page.goto(server.empty_page).wait!
        context.override_permissions server.empty_page, []
        expect(get_permission(page, 'geolocation')).to eq 'denied'
      end

      it 'should fail when bad permission is given' do
        page.goto(server.empty_page).wait!
        expect { context.override_permissions(server.empty_page, ['foo']) }
          .to raise_error 'Unknown permission: foo'
      end

      it 'should grant permission when listed' do
        page.goto(server.empty_page).wait!
        context.override_permissions server.empty_page, ['geolocation']
        expect(get_permission(page, 'geolocation')).to eq 'granted'
      end

      it 'should reset permissions' do
        page.goto(server.empty_page).wait!
        context.override_permissions server.empty_page, ['geolocation']
        expect(get_permission(page, 'geolocation')).to eq 'granted'
        context.clear_permission_overrides
        expect(get_permission(page, 'geolocation')).to eq 'prompt'
      end

      it 'should trigger permission onchange' do
        page.goto(server.empty_page).wait!
        page.evaluate_function("() => {
          window.events = [];
          return navigator.permissions.query({name: 'geolocation'}).then(function(result) {
            window.events.push(result.state);
            result.onchange = function() {
              window.events.push(result.state);
            };
          });
        }").wait!
        expect(page.evaluate_function("() => window.events").value!).to eq ['prompt']
        context.override_permissions server.empty_page, []
        expect(page.evaluate_function("() => window.events").value!).to eq ['prompt', 'denied']
        context.override_permissions server.empty_page, ['geolocation']
        expect(page.evaluate_function("() => window.events").value!).to eq ['prompt', 'denied', 'granted']
        context.clear_permission_overrides
        expect(page.evaluate_function("() => window.events").value!).to eq ['prompt', 'denied', 'granted', 'prompt']
      end

      it 'should isolate permissions between browser contexs' do
        page.goto(server.empty_page).wait!
        other_context = browser.create_context
        other_page = other_context.new_page
        other_page.goto(server.empty_page).wait!
        expect(get_permission(page, 'geolocation')).to eq 'prompt'
        expect(get_permission(other_page, 'geolocation')).to eq 'prompt'

        context.override_permissions server.empty_page, []
        other_context.override_permissions server.empty_page, ['geolocation']
        expect(get_permission(page, 'geolocation')).to eq 'denied'
        expect(get_permission(other_page, 'geolocation')).to eq 'granted'

        context.clear_permission_overrides
        expect(get_permission(page, 'geolocation')).to eq 'prompt'
        expect(get_permission(other_page, 'geolocation')).to eq 'granted'

        other_context.close
      end
    end

    describe 'Page.set_geolocation' do
      it 'should work' do
        context.override_permissions server.domain, ['geolocation']
        page.goto(server.empty_page).wait!
        page.set_geolocation longitude: 10, latitude: 10
        geolocation = page.evaluate_function("() => new Promise(resolve => navigator.geolocation.getCurrentPosition(position => {
          resolve({latitude: position.coords.latitude, longitude: position.coords.longitude});
        }))").value!
        expect(geolocation).to eq "latitude" => 10, "longitude" => 10
      end

      it 'should throw when invalid longitude' do
        expect { page.set_geolocation longitude: 200, latitude: 10 }
          .to raise_error(/Invalid longitude '200'/)
      end
    end

    describe 'Page.set_offline_mode' do
      it 'should work' do
        page.set_offline_mode true
        expect { page.goto(server.empty_page).wait! }.to raise_error(/net::ERR_INTERNET_DISCONNECTED/)
        page.set_offline_mode false
        response = page.reload.value!
        expect(response.status).to eq 200
      end

      it 'should emulate navigator.onLine' do
        expect(page.evaluate_function("() => window.navigator.onLine").value!).to eq true
        page.set_offline_mode true
        expect(page.evaluate_function("() => window.navigator.onLine").value!).to eq false
        page.set_offline_mode false
        expect(page.evaluate_function("() => window.navigator.onLine").value!).to eq true
      end
    end

    describe 'ExecutionContext#query_objects' do
      it 'should work' do
        # Instantiate an object
        page.evaluate_function("() => window.set = new Set(['hello', 'world'])").wait!
        prototype_handle = page.evaluate_handle_function("() => Set.prototype").value!
        objects_handle = page.query_objects prototype_handle
        count = page.evaluate_function("objects => objects.length", objects_handle).value!
        expect(count).to eq 1
        values = page.evaluate_function("objects => Array.from(objects[0].values())", objects_handle).value!
        expect(values).to eq ['hello', 'world']
      end

      it 'should work for non-blank page' do
        page.goto(server.empty_page).wait!
        page.evaluate_function("() => window.set = new Set(['hello', 'world'])").wait!
        prototype_handle = page.evaluate_handle_function("() => Set.prototype").value!
        objects_handle = page.query_objects prototype_handle
        count = page.evaluate_function("objects => objects.length", objects_handle).value!
        expect(count).to eq 1
      end

      it 'should fail for disposed handles' do
        prototype_handle = page.evaluate_handle_function("() => HTMLBodyElement.prototype").value!
        prototype_handle.dispose
        expect { page.query_objects(prototype_handle) }.to raise_error 'Prototype JSHandle is disposed!'
      end

      it 'should fail primitive values as prototypes' do
        prototype_handle = page.evaluate_handle_function("() => 42").value!
        expect { page.query_objects prototype_handle }
          .to raise_error 'Prototype JSHandle must not be referencing primitive value'
      end
    end

    describe 'Page.Events.Console' do
      it 'should work' do
        message = nil
        page.once :console, ->(m) { message = m }
        Concurrent::Promises.zip(
          page.evaluate_function("() => console.log('hello', 5, {foo: 'bar'})"),
          wait_event(page, :console)
        ).wait!
        expect(message.text).to eq 'hello 5 JSHandle@object'
        expect(message.type).to eq 'log'
        expect(message.args[0].json_value).to eq 'hello'
        expect(message.args[1].json_value).to eq 5
        expect(message.args[2].json_value).to eq 'foo' => 'bar'
      end

      it 'should work for different console API calls' do
        messages = []
        page.on :console, ->(msg) { messages << msg }
        # All console events will be reported before `page.evaluate` is finished.
        page.evaluate_function("() => {
          // A pair of time/timeEnd generates only one Console API call.
          console.time('calling console.time');
          console.timeEnd('calling console.time');
          console.trace('calling console.trace');
          console.dir('calling console.dir');
          console.warn('calling console.warn');
          console.error('calling console.error');
          console.log(Promise.resolve('should not wait until resolved!'));
        }").wait!
        expect(messages.map(&:type)).to eq ['timeEnd', 'trace', 'dir', 'warning', 'error', 'log']
        expect(messages[0].text).to include 'calling console.time'
        expect(messages.tap(&:shift).map(&:text)).to eq [
          'calling console.trace',
          'calling console.dir',
          'calling console.warn',
          'calling console.error',
          'JSHandle@promise'
        ]
      end

      it 'should not fail for window object' do
        message = nil
        page.once :console, ->(msg) { message = msg }
        Concurrent::Promises.zip(
          wait_event(page, :console),
          page.evaluate_function("() => console.error(window)")
        ).wait!
        expect(message.text).to eq 'JSHandle@object'
      end

      it 'should trigger correct Log' do
        page.goto('about:blank').wait!
        message, _ = Concurrent::Promises.zip(
          wait_event(page, :console),
          page.evaluate_function("async url => fetch(url).catch(e => {})", server.empty_page)
        ).value!
        expect(message.text).to include 'Access-Control-Allow-Origin'
        expect(message.type).to eq 'error'
      end

      it 'should have location when fetch fails' do
        # The point of this test is to make sure that we report console messages from
        # Log domain: https://vanilla.aslushnikov.com/?Log.entryAdded
        page.goto(server.empty_page).wait!
        message, _ = Concurrent::Promises.zip(
          wait_event(page, :console),
          page.set_content("<script>fetch('http://wat');</script>")
        ).value!
        expect(message.text).to include "ERR_NAME_NOT_RESOLVED"
        expect(message.type).to eq 'error'
        expect(message.location).to eq url: 'http://wat/', line_number: nil
      end

      it 'should have location for console API calls' do
        message, _ =  Concurrent::Promises.zip(
          wait_event(page, :console),
          page.goto(server.domain + 'consolelog.html')
        ).value!
        expect(message.text).to eq 'yellow'
        expect(message.type).to eq 'log'
        expect(message.location).to eq url: server.domain + 'consolelog.html', line_number: 7, column_number: 14
      end

      # @see https://github.com/GoogleChrome/puppeteer/issues/3865
      it 'should not throw when there are console messages in detached iframes' do
        page.goto(server.empty_page).wait!
        page.evaluate_function("async() => {
          // 1. Create a popup that Puppeteer is not connected to.
          win = window.open(window.location.href, 'Title', 'toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,width=780,height=200,top=0,left=0');
          await new Promise(x => win.onload = x);
          // 2. In this popup, create an iframe that console.logs a message.
          win.document.body.innerHTML = `<iframe src='/consolelog.html'></iframe>`;
          frame = win.document.querySelector('iframe');
          await new Promise(x => frame.onload = x);
          // 3. After that, remove the iframe.
          frame.remove();
        }").wait!
        popup_target = page.browser_context.targets.detect { |target| target != page.target }
        # 4. Connect to the popup and make sure it doesn't throw.
        popup_target.page
      end
    end

    describe 'Page.Events.DOMContentLoaded' do
      it 'should fire when expected' do
        Concurrent::Promises.zip(
          wait_event(page, :dom_content_loaded),
          page.goto('about:blank')
        ).wait!
      end
    end

    describe 'Page.metrics' do
      def check_metrics(metrics)
        metrics_to_check = [
          'Timestamp',
          'Documents',
          'Frames',
          'JSEventListeners',
          'Nodes',
          'LayoutCount',
          'RecalcStyleCount',
          'LayoutDuration',
          'RecalcStyleDuration',
          'ScriptDuration',
          'TaskDuration',
          'JSHeapUsedSize',
          'JSHeapTotalSize'
        ]
        metrics.each do |name, metric|
          expect(metrics_to_check.include?(name)).to eq true
          expect(metric).to be >= 0
          metrics_to_check.delete name
        end
        expect(metrics_to_check.size).to eq 0
      end

      it 'should get metrics from a page' do
        page.goto('about:blank').wait!
        metrics = page.metrics
        check_metrics metrics
      end

      it 'metrics event fired on console.timeStamp' do
        metrics_promise = Concurrent::Promises.resolvable_future.tap do |future|
          page.once :metrics, future.method(:fulfill)
        end
        page.evaluate_function("() => console.timeStamp('test42')").wait!
        metrics = metrics_promise.value!
        expect(metrics["title"]).to eq 'test42'
        check_metrics(metrics["metrics"])
      end
    end

    describe 'Page#wait_for_request' do
      it 'should work' do
        page.goto(server.empty_page).wait!
        request, _ = Concurrent::Promises.zip(
          page.wait_for_request(server.domain + 'digits/2.png'),
          page.evaluate_function("() => {
            fetch('/digits/1.png');
            fetch('/digits/2.png');
            fetch('/digits/3.png');
          }")
        ).value!
        expect(request.url).to eq server.domain + 'digits/2.png'
      end

      it 'should work with predicate' do
        page.goto(server.empty_page).wait!
        request, _ = Concurrent::Promises.zip(
          page.wait_for_request { |r| r.url == server.domain + 'digits/2.png' },
          page.evaluate_function("() => {
            fetch('/digits/1.png');
            fetch('/digits/2.png');
            fetch('/digits/3.png');
          }")
        ).value!
        expect(request.url).to eq server.domain + 'digits/2.png'
      end

      it 'should work with no timeout' do
        page.goto(server.empty_page).wait!
        request, _ = Concurrent::Promises.zip(
          page.wait_for_request(server.domain + 'digits/2.png'),
          page.evaluate_function("() => setTimeout(() => {
            fetch('/digits/1.png');
            fetch('/digits/2.png');
            fetch('/digits/3.png');
          }, 50)")
        ).value!
        expect(request.url).to eq server.domain + 'digits/2.png'
      end
    end

    describe 'Page#wait_for_response' do
      it 'should work' do
        page.goto(server.empty_page).wait!
        response, _ = Concurrent::Promises.zip(
          page.wait_for_response(server.domain + 'digits/2.png'),
          page.evaluate_function("() => {
            fetch('/digits/1.png');
            fetch('/digits/2.png');
            fetch('/digits/3.png');
          }")
        ).value!
        expect(response.url).to eq server.domain + 'digits/2.png'
      end

      it 'should work with predicate' do
        page.goto(server.empty_page).wait!
        response, _ = Concurrent::Promises.zip(
          page.wait_for_response { |r| r.url == server.domain + 'digits/2.png' },
          page.evaluate_function("() => {
            fetch('/digits/1.png');
            fetch('/digits/2.png');
            fetch('/digits/3.png');
          }")
        ).value!
        expect(response.url).to eq server.domain + 'digits/2.png'
      end

      it 'should work with no timeout' do
        page.goto(server.empty_page).wait!
        response, _ = Concurrent::Promises.zip(
          page.wait_for_response(server.domain + 'digits/2.png'),
          page.evaluate_function("() => setTimeout(() => {
            fetch('/digits/1.png');
            fetch('/digits/2.png');
            fetch('/digits/3.png');
          }, 50)")
        ).value!
        expect(response.url).to eq server.domain + 'digits/2.png'
      end
    end

    describe 'Page#expose_function' do
      it 'should work' do
        page.expose_function 'compute' do |a, b|
          a * b
        end
        result = page.evaluate_function("async function() {
          return await compute(9, 4);
        }").value!
        expect(result).to eq 36
      end

      it 'should throw exception in page context' do
        page.expose_function 'woof' do
          raise 'WOOF WOOF'
        end
        result = page.evaluate_function("async() => {
          try {
            await woof();
          } catch (e) {
            return {message: e.message, stack: e.stack};
          }
        }").value!
        expect(result["message"]).to eq 'WOOF WOOF'
        expect(result["stack"].any? { |location| location.match?(/#{__FILE__}/) }).to eq true
      end

      it 'should be callable from-inside evaluate_on_new_document' do
        called = false
        page.expose_function 'woof' do
          called = true
        end
        page.evaluate_on_new_document('() => woof()')
        page.reload.wait!
        expect(called).to eq true
      end

      it 'should survive navigation' do
        page.expose_function 'compute' do |a, b|
          a * b
        end

        page.goto(server.empty_page).wait!
        result = page.evaluate_function("async function() {
          return await compute(9, 4);
        }").value!
        expect(result).to eq 36
      end

      it 'should await returned promise' do
        page.expose_function 'compute' do |a, b|
          Concurrent::Promises.fulfilled_future(a * b)
        end

        result = page.evaluate_function("async function() {
          return await compute(3, 5);
        }").value!
        expect(result).to eq 15
      end

      it 'should work on frames' do
        page.expose_function 'compute' do |a, b|
          Concurrent::Promises.fulfilled_future(a * b)
        end

        page.goto(server.domain + 'frames/nested-frames.html').wait!
        frame = page.frames[1]
        result = frame.evaluate_function("async function() {
          return await compute(3, 5);
        }").value!
        expect(result).to eq 15
      end

      it 'should work on frames before navigation' do
        page.goto(server.domain + 'frames/nested-frames.html').wait!
        page.expose_function 'compute' do |a, b|
          Concurrent::Promises.fulfilled_future(a * b)
        end

        frame = page.frames[1]
        result = frame.evaluate_function("async function() {
          return await compute(3, 5);
        }").value!
        expect(result).to eq 15
      end

      it 'should work with complex objects' do
        page.expose_function 'complexObject' do |a, b|
          { x: a["x"] + b["x"] }
        end
        result = page.evaluate_function("async() => complexObject({x: 5}, {x: 2})").value!
        expect(result["x"]).to eq 7
      end
    end

    describe 'Page.Events.PageError' do
      it 'should fire' do
        error = nil
        page.once :page_error, ->(e) { error = e }
        Concurrent::Promises.zip(
          wait_event(page, :page_error),
          page.goto(server.domain + 'error.html')
        ).wait!
        expect(error.message).to include 'Fancy'
      end
    end

    describe 'Page#set_user_agent' do
      it 'should work' do
        expect(page.evaluate_function("() => navigator.userAgent").value!).to include 'Mozilla'
        page.set_user_agent 'foobar'
        request, _ = Concurrent::Promises.zip(
          server.wait_for_request('/empty.html'),
          page.goto(server.empty_page)
        ).value!
        expect(request.headers['user-agent']).to eq 'foobar'
      end

      it 'should work for subframes' do
        expect(page.evaluate_function("() => navigator.userAgent").value!).to include 'Mozilla'
        page.set_user_agent('foobar')
        request, _ = Concurrent::Promises.zip(
          server.wait_for_request('/empty.html'),
          attach_frame(page, 'frame1', server.empty_page)
        ).value!
        expect(request.headers['user-agent']).to eq 'foobar'
      end

      it 'should emulate device user-agent' do
        page.goto(server.domain + 'mobile.html').wait!
        expect(page.evaluate_function("() => navigator.userAgent").value!).not_to include 'iPhone'
        page.set_user_agent(Rammus.devices['iPhone 6'][:user_agent])
        expect(page.evaluate_function("() => navigator.userAgent").value!).to include 'iPhone'
      end
    end

    describe 'Page#set_content' do
      let(:expected_output) { '<html><head></head><body><div>hello</div></body></html>' }

      it 'sets page content' do
        page.set_content('<div>hello</div>').wait!
        result = page.content
        expect(result).to eq expected_output
      end

      it 'should work with doctype' do
        doctype = '<!DOCTYPE html>'
        page.set_content("#{doctype}<div>hello</div>").wait!
        result = page.content
        expect(result).to eq "#{doctype}#{expected_output}"
      end

      it 'should work with HTML 4 doctype' do
        doctype = '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">'
        page.set_content("#{doctype}<div>hello</div>").wait!
        result = page.content
        expect(result).to eq "#{doctype}#{expected_output}"
      end

      it 'should respect timeout' do
        img_path = 'timeout-img.png'
        server.set_route("/#{img_path}") { |_req, _res| Concurrent::Promises.resolvable_future.wait! }
        expect do
          page.set_content("<img src='#{server.domain + img_path}'></img>", timeout: 0.01).wait!
        end.to raise_error(Errors::TimeoutError, /Navigation Timeout Exceeded/)
      end

      it 'should respect default navigation timeout' do
        page.set_default_navigation_timeout 1
        img_path = 'img.png'
        # stall for image
        server.set_route("/#{img_path}") { |_req, _res| Concurrent::Promises.resolvable_future.wait! }
        expect { page.set_content("<img src='#{server.domain + img_path}'></img>").wait! }
          .to raise_error(Errors::TimeoutError, /Navigation Timeout Exceeded/)
      end

      it 'should await resources to load' do
        img_path = '/img.png'
        img_response = server.hang_route img_path

        loaded = false
        image_requested = server.wait_for_request(img_path)
        content_promise = page.set_content("<img src='#{server.domain + 'img.png'}'></img>").then { loaded = true }
        image_requested.wait!

        expect(loaded).to eq false
        img_response.(nil)
        content_promise.wait!
      end

      it 'should work fast enough' do
        20.times { page.set_content('<div>yo</div>').wait! }
      end

      it 'should work with tricky content' do
        page.set_content("<div>hello world</div>\x7F").wait!
        expect(page.query_selector_evaluate_function('div', "div => div.textContent").value!).to eq 'hello world'
      end

      it 'should work with accents' do
        page.set_content('<div>aberración</div>').wait!
        expect(page.query_selector_evaluate_function('div', "div => div.textContent").value!).to eq 'aberración'
      end

      it 'should work with emojis' do
        page.set_content('<div>🐥</div>').wait!
        expect(page.query_selector_evaluate_function('div', "div => div.textContent").value!).to eq '🐥'
      end

      it 'should work with newline' do
        page.set_content("<div>\n</div>").wait!
        expect(page.query_selector_evaluate_function('div', "div => div.textContent").value!).to eq "\n"
      end
    end

    describe 'Page#set_bypass_csp' do
      it 'should bypass CSP meta tag' do
        # Make sure CSP prohibits add_script_tag.
        page.goto(server.domain + 'csp.html').wait!
        page.add_script_tag content: 'window.__injected = 42;'
        expect(page.evaluate_function("() => window.__injected").value!).to eq nil

        ## By-pass CSP and try one more time.
        page.set_bypass_csp true
        page.reload.wait!
        page.add_script_tag content: 'window.__injected = 42;'
        expect(page.evaluate_function("() => window.__injected").value!).to eq 42
      end

      it 'should bypass CSP header' do
        # Make sure CSP prohibits add_script_tag.
        server.set_content_security_policy '/empty.html', 'default-src "self"'
        page.goto(server.empty_page).wait!
        page.add_script_tag content: 'window.__injected = 42;'
        expect(page.evaluate_function("() => window.__injected").value!).to eq nil

        # By-pass CSP and try one more time.
        page.set_bypass_csp true
        page.reload.wait!
        page.add_script_tag content: 'window.__injected = 42;'
        expect(page.evaluate_function("() => window.__injected").value!).to eq 42
      end

      it 'should bypass after cross-process navigation' do
        page.set_bypass_csp true
        page.goto(server.domain + 'csp.html').wait!
        page.add_script_tag content: 'window.__injected = 42;'
        expect(page.evaluate_function("() => window.__injected").value!).to eq 42

        page.goto(server.cross_process_domain + 'csp.html').wait!
        page.add_script_tag content: 'window.__injected = 42;'
        expect(page.evaluate_function("() => window.__injected").value!).to eq 42
      end

      it 'should bypass CSP in iframes as well' do
        page.goto(server.empty_page).wait!

        # Make sure CSP prohibits add_script_tag in an iframe.
        frame = attach_frame(page, 'frame1', server.domain + 'csp.html').value!
        frame.add_script_tag content: 'window.__injected = 42;'
        expect(frame.evaluate_function("() => window.__injected").value!).to eq nil

        # By-pass CSP and try one more time.
        page.set_bypass_csp true
        page.reload.wait!

        frame = attach_frame(page, 'frame1', server.domain + 'csp.html').value!
        frame.add_script_tag content: 'window.__injected = 42;'
        expect(frame.evaluate_function("() => window.__injected").value!).to eq 42
      end
    end

    describe 'Page#add_script_tag' do
      it 'should throw an error if no options are provided' do
        expect { page.add_script_tag }
          .to raise_error "Provide an object with a `url`, `path` or `content` property"
      end

      it 'should work with a url' do
        page.goto(server.empty_page).wait!
        script_handle = page.add_script_tag url: '/injectedfile.js'
        expect(script_handle.as_element).not_to be_nil
        expect(page.evaluate_function("() => __injected").value!).to eq 42
      end

      it 'should work with a url and type=module' do
        page.goto(server.empty_page).wait!
        page.add_script_tag url: '/es6/es6import.js', type: 'module'
        expect(page.evaluate_function("() => __es6injected").value!).to eq 42
      end

      it 'should work with a path and type=module' do
        page.goto(server.empty_page).wait!

        path = File.expand_path("../../support/public/es6/es6pathimport.js", File.dirname(__FILE__))
        page.add_script_tag(path: path, type: 'module')
        page.wait_for_function('window.__es6injected').wait!
        expect(page.evaluate_function("() => __es6injected").value!).to eq 42
      end

      it 'should work with a content and type=module' do
        page.goto(server.empty_page).wait!
        page.add_script_tag content: "import num from '/es6/es6module.js';window.__es6injected = num;", type: 'module'
        page.wait_for_function('window.__es6injected').wait!
        expect(page.evaluate_function("() => __es6injected").value!).to eq 42
      end

      it 'should throw an error if loading from url fail' do
        page.goto(server.empty_page).wait!
        expect { page.add_script_tag url: '/nonexistfile.js' }
          .to raise_error 'Loading script from /nonexistfile.js failed'
      end

      it 'should work with a path' do
        page.goto(server.empty_page).wait!
        path = File.expand_path("../../support/public/injectedfile.js", File.dirname(__FILE__))
        script_handle = page.add_script_tag path: path
        expect(script_handle.as_element).not_to be_nil
        expect(page.evaluate_function("() => __injected").value!).to eq 42
      end

      it 'should include sourcemap when path is provided' do
        page.goto(server.empty_page).wait!
        path = File.expand_path("../../support/public/injectedfile.js", File.dirname(__FILE__))
        page.add_script_tag path: path
        result = page.evaluate_function("() => __injectedError.stack").value!
        expect(result).to include 'public/injectedfile.js'
      end

      it 'should work with content' do
        page.goto(server.empty_page).wait!
        script_handle = page.add_script_tag content: 'window.__injected = 35;'
        expect(script_handle.as_element).not_to be_nil
        expect(page.evaluate_function("() => __injected").value!).to eq 35
      end

      # https://github.com/puppeteer/puppeteer/issues/4840
      xit 'should throw when added with content to the CSP page' do
        page.goto(server.domain + 'csp.html').wait!
        expect { page.add_script_tag content: 'window.__injected = 35;' }
          .to raise_error(/Evaluation failed/)
      end

      it 'should throw when added with URL to the CSP page' do
        page.goto(server.domain + 'csp.html').wait!
        expect { page.add_script_tag url: server.cross_process_domain + 'injectedfile.js' }
          .to raise_error(/Loading script from #{server.cross_process_domain + 'injectedfile.js'} failed/)
      end
    end

    describe 'Page#add_style_tag' do
      it 'should throw an error if no options are provided' do
        expect { page.add_style_tag.wait! }
          .to raise_error 'Provide a `url`, `path` or `content`'
      end

      it 'should work with a url' do
        page.goto(server.empty_page).wait!
        style_handle = page.add_style_tag url: '/injectedstyle.css'
        expect(style_handle.as_element).not_to be_nil
        expect(page.evaluate("window.getComputedStyle(document.querySelector('body')).getPropertyValue('background-color')").value!).to eq 'rgb(255, 0, 0)'
      end

      it 'should throw an error if loading from url fail' do
        page.goto(server.empty_page).wait!
        expect { page.add_style_tag url: '/nonexistfile.js' }
          .to raise_error 'Loading style from /nonexistfile.js failed'
      end

      it 'should work with a path' do
        page.goto(server.empty_page).wait!
        path = File.expand_path("../../support/public/injectedstyle.css", File.dirname(__FILE__))
        style_handle = page.add_style_tag path: path
        expect(style_handle.as_element).not_to be_nil
        expect(page.evaluate("window.getComputedStyle(document.querySelector('body')).getPropertyValue('background-color')").value!).to eq 'rgb(255, 0, 0)'
      end

      it 'should include sourcemap when path is provided' do
        page.goto(server.empty_page).wait!
        path = File.expand_path("../../support/public/injectedstyle.css", File.dirname(__FILE__))
        page.add_style_tag path: path
        style_handle = page.query_selector 'style'
        style_content = page.evaluate_function("style => style.innerHTML", style_handle).value!
        expect(style_content).to include 'public/injectedstyle.css'
      end

      it 'should work with content' do
        page.goto(server.empty_page).wait!
        style_handle = page.add_style_tag content: 'body { background-color: green; }'
        expect(style_handle.as_element).not_to be_nil
        expect(page.evaluate("window.getComputedStyle(document.querySelector('body')).getPropertyValue('background-color')").value!).to eq 'rgb(0, 128, 0)'
      end

      it 'should throw when added with content to the CSP page' do
        page.goto(server.domain + 'csp.html').wait!
        expect { page.add_style_tag content: 'body { background-color: green; }' }
          .to raise_error(/Evaluation failed/)
      end

      it 'should throw when added with URL to the CSP page' do
        page.goto(server.domain + 'csp.html').wait!
        expect { page.add_style_tag url: server.cross_process_domain + 'injectedstyle.css' }
          .to raise_error(/Loading style from #{server.cross_process_domain + 'injectedstyle.css'} failed/)
      end
    end

    describe '#url' do
      it 'returns the pages current url' do
        expect(page.url).to eq "about:blank"
        page.goto(server.empty_page).wait!
        expect(page.url).to eq server.empty_page
      end
    end

    describe 'Page#set_javascript_enabled' do
      it 'should work' do
        page.set_javascript_enabled false
        page.goto('data:text/html, <script>var something = "forbidden"</script>').wait!

        expect { page.evaluate('something').value! }
          .to raise_error(/something is not defined/)

        page.set_javascript_enabled true
        page.goto('data:text/html, <script>var something = "forbidden"</script>').wait!
        expect(page.evaluate('something').value!).to eq 'forbidden'
      end
    end

    describe 'Page#set_cache_enabled' do
      it 'should enable or disable the cache based on the state passed' do
        page.goto(server.domain + 'cached/one-style.html').wait!
        cached_request, _ = Concurrent::Promises.zip(
          server.wait_for_request('/cached/one-style.html'),
          page.reload
        ).value!
        # Rely on "if-modified-since" caching in our test server.
        expect(cached_request.headers['if-modified-since']).not_to eq nil

        page.set_cache_enabled false
        non_cached_request, _ = Concurrent::Promises.zip(
          server.wait_for_request('/cached/one-style.html'),
          page.reload
        ).value!
        expect(non_cached_request.headers['if-modified-since']).to eq nil
      end

      it 'should stay disabled when toggling request interception on/off' do
        page.set_cache_enabled false
        page.set_request_interception true
        page.set_request_interception false

        page.goto(server.domain + 'cached/one-style.html').wait!
        non_cached_request, _ = Concurrent::Promises.zip(
          server.wait_for_request('/cached/one-style.html'),
          page.reload
        ).value!
        expect(non_cached_request.headers['if-modified-since']).to eq nil
      end
    end

    describe 'Page#pdf' do
      it 'should be able to save file' do
        output_file = File.expand_path("../../tmp/output.pdf", File.dirname(__FILE__))

        page.pdf path: output_file
        expect(File.size(output_file)).to be > 0
        File.delete output_file
      end
    end

    describe '#title' do
      it 'should return the page title' do
        page.goto(server.domain + "/title.html").wait!
        expect(page.title).to eq 'Woof-Woof'
      end
    end

    describe 'Page.select' do
      it 'should select single option' do
        page.goto(server.domain + 'input/select.html').wait!
        page.select 'select', 'blue'
        expect(page.evaluate_function("() => result.onInput").value!).to eq ['blue']
        expect(page.evaluate_function("() => result.onChange").value!).to eq ['blue']
      end

      it 'should select only first option' do
        page.goto(server.domain + '/input/select.html').wait!
        page.select 'select', 'blue', 'green', 'red'
        expect(page.evaluate_function("() => result.onInput").value!).to eq ['blue']
        expect(page.evaluate_function("() => result.onChange").value!).to eq ['blue']
      end

      it 'should not throw when select causes navigation' do
        page.goto(server.domain + 'input/select.html').wait!
        page.query_selector_evaluate_function 'select', "select => select.addEventListener('input', () => window.location = '/empty.html')"
        Concurrent::Promises.zip(
          page.wait_for_navigation,
          Concurrent::Promises.future { page.select('select', 'blue') }
        ).wait!
        expect(page.url).to include 'empty.html'
      end

      it 'should select multiple options' do
        page.goto(server.domain + 'input/select.html').wait!
        page.evaluate_function("() => makeMultiple()").wait!
        page.select 'select', 'blue', 'green', 'red'
        expect(page.evaluate_function("() => result.onInput").value!).to eq ['blue', 'green', 'red']
        expect(page.evaluate_function("() => result.onChange").value!).to eq ['blue', 'green', 'red']
      end

      it 'should respect event bubbling' do
        page.goto(server.domain + 'input/select.html').wait!
        page.select 'select', 'blue'
        expect(page.evaluate_function("() => result.onBubblingInput").value!).to eq ['blue']
        expect(page.evaluate_function("() => result.onBubblingChange").value!).to eq ['blue']
      end

      it 'should throw when element is not a <select>' do
        page.goto(server.domain + '/input/select.html').wait!
        expect { page.select('body', '') }.to raise_error(/Element is not a <select> element./)
      end

      it 'should return [] on no matched values' do
        page.goto(server.domain + 'input/select.html').wait!
        result = page.select 'select', '42', 'abc'
        expect(result).to eq []
      end

      it 'should return an array of matched values' do
        page.goto(server.domain + 'input/select.html').wait!
        page.evaluate_function("() => makeMultiple()").wait!
        result = page.select 'select', 'blue', 'black', 'magenta'
        expect(result).to match_array(['blue', 'black', 'magenta'])
      end

      it 'should return an array of one element when multiple is not set' do
        page.goto(server.domain + 'input/select.html').wait!
        result = page.select 'select', '42', 'blue', 'black', 'magenta'
        expect(result.length).to eq 1
      end

      it 'should return [] on no values' do
        page.goto(server.domain + 'input/select.html').wait!
        result = page.select 'select'
        expect(result).to eq []
      end

      it 'should deselect all options when passed no values for a multiple select' do
        page.goto(server.domain + 'input/select.html').wait!
        page.evaluate_function("() => makeMultiple()").wait!
        page.select 'select', 'blue', 'black', 'magenta'
        page.select 'select'
        result = page.query_selector_evaluate_function('select', "select => Array.from(select.options).every(option => !option.selected)").value!
        expect(result).to eq true
      end

      it 'should deselect all options when passed no values for a select without multiple' do
        page.goto(server.domain + 'input/select.html').wait!
        page.select 'select', 'blue', 'black', 'magenta'
        page.select 'select'
        result = page.query_selector_evaluate_function('select', "select => Array.from(select.options).every(option => !option.selected)").value!
        expect(result).to eq true
      end

      it 'should throw if passed in non-strings' do
        page.set_content('<select><option value="12"/></select>').wait!

        expect { page.select('select', 12) }.to raise_error(/Values must be strings/)
      end

      # @see https://github.com/GoogleChrome/puppeteer/issues/3327
      it 'should work when re-defining top-level Event class' do
        page.goto(server.domain + 'input/select.html').value!
        page.evaluate_function("() => window.Event = null").wait!
        page.select 'select', 'blue'
        expect(page.evaluate_function("() => result.onInput").value!).to eq ['blue']
        expect(page.evaluate_function("() => result.onChange").value!).to eq ['blue']
      end
    end

    describe 'Page.Events.Close' do
      it 'should work with window.close' do
        new_page_promise = Concurrent::Promises.resolvable_future.tap do |future|
          context.once :target_created, ->(target) { future.fulfill target.page }
        end
        page.evaluate_function("() => window['new_page'] = window.open('about:blank')").wait!
        new_page = new_page_promise.value!
        closed_promise = Concurrent::Promises
          .resolvable_future
          .tap { |future| new_page.on :close, future.method(:fulfill) }
        page.evaluate_function("() => window['new_page'].close()").wait!
        closed_promise.wait!
      end

      it 'should work with page.close' do
        new_page = context.new_page
        closed_promise = Concurrent::Promises.resolvable_future.tap do |future|
          new_page.on :close, future.method(:fulfill)
        end
        new_page.close
        closed_promise.wait!
      end
    end

    describe 'Page.browser' do
      it 'should return the correct browser instance' do
        expect(page.browser).to eq browser
      end
    end

    describe 'Page.browserContext' do
      it 'should return the correct browser instance' do
        expect(page.browser_context).to eq context
      end
    end
  end
end
