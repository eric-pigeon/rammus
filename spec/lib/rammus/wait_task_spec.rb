module Rammus
  RSpec.describe WaitTask, page: true do
    describe 'Frame#wait_for_function' do
      it 'should accept a string' do
        watchdog = page.wait_for_function('window.__FOO === 1')
        page.evaluate_function("() => window.__FOO = 1").wait!
        watchdog.wait!
      end

      it 'should work when resolved right before execution context disposal' do
        page.evaluate_on_new_document "() => window.__RELOADED = true"
        page.wait_for_function("() => {
          if (!window.__RELOADED)
            window.location.reload();
          return true;
        }").wait!
      end

      it 'should poll on interval' do
        pending 'what'
        success = false
        start_time = Time.now
        polling = 100
        watchdog = page.wait_for_function("() => window.__FOO === 'hit'", polling: polling)
            .then { success = true }
        page.evaluate_function("() => window.__FOO = 'hit'").wait!
        expect(success).to eq false
        page.evaluate_function("() => document.body.appendChild(document.createElement('div'))").wait!
        watchdog.wait!
        expect(Time.now - start_time).to be >= (polling / 2)
      end

      it 'should poll on mutation' do
        success = false
        watchdog = page.wait_for_function("() => window.__FOO === 'hit'", polling: 'mutation')
            .then { success = true }
        page.evaluate_function("() => window.__FOO = 'hit'").wait!
        expect(success).to eq false
        page.evaluate_function("() => document.body.appendChild(document.createElement('div'))").wait!
        watchdog.wait!
      end

      it 'should poll on raf' do
        watchdog = page.wait_for_function "() => window.__FOO === 'hit'", polling: 'raf'
        page.evaluate_function("() => window.__FOO = 'hit'").wait!
        watchdog.wait!
      end

      it 'should work with strict CSP policy' do
        server.set_content_security_policy '/empty.html', 'script-src ' + server.domain
        page.goto(server.empty_page).wait!
        error = nil
        Concurrent::Promises.zip(
          page.wait_for_function("() => window.__FOO === 'hit'", polling: 'raf').rescue { |e| error = e },
          page.evaluate_function("() => window.__FOO = 'hit'")
        ).wait!
        expect(error).to eq nil
      end

      it 'should throw on bad polling value' do
        expect do
          page.wait_for_function("() => !!document.body", polling: 'unknown').wait!
        end.to raise_error(/polling/)
      end

      it 'should throw negative polling interval' do
        expect do
          page.wait_for_function("() => !!document.body", polling: -10).wait!
        end.to raise_error(/Cannot poll with non-positive interval/)
      end

      it 'should return the success value as a JSHandle' do
        # TODO, allow functions in wait for function, passing empty args for now to
        # force a function call
        expect((page.wait_for_function("() => 5", []).value!).json_value).to eq 5
      end

      it 'should return the window as a success value' do
        expect(page.wait_for_function("() => window", []).value!).not_to be_nil
      end

      it 'should accept ElementHandle arguments' do
        page.set_content('<div></div>').wait!
        div = page.query_selector 'div'
        resolved = false
        wait_for_function = page.wait_for_function("element => !element.parentElement", {}, div).then { resolved = true }
        expect(resolved).to eq false
        page.evaluate_function("element => element.remove()", div).wait!
        wait_for_function.wait!
      end

      it 'should respect timeout' do
        expect { page.wait_for_function('false', timeout: 0.1).wait! }
          .to raise_error(Errors::TimeoutError, /waiting for function failed: timeout/)
      end

      it 'should respect default timeout' do
        page.set_default_timeout 0.1

        expect { page.wait_for_function('false', timeout: 0.1).wait! }
          .to raise_error(Errors::TimeoutError, /waiting for function failed: timeout/)
      end

      it 'should disable timeout when its set to 0' do
        watchdog = page.wait_for_function("() => {
          window.__counter = (window.__counter || 0) + 1;
          return window.__injected;
        }", timeout: 0, polling: 10)
        page.wait_for_function("() => window.__counter > 10").wait!
        page.evaluate_function("() => window.__injected = true").wait!
        watchdog.wait!
      end

      it 'should survive cross-process navigation' do
        foo_found = false
        wait_for_function = page.wait_for_function('window.__FOO === 1').then { foo_found = true }
        page.goto(server.empty_page).wait!
        expect(foo_found).to eq false
        page.reload.wait!
        expect(foo_found).to eq false
        page.goto(server.cross_process_domain + 'grid.html').wait!
        expect(foo_found).to eq false
        page.evaluate_function("() => window.__FOO = 1").wait!
        wait_for_function.wait!
        expect(foo_found).to eq true
      end

      it 'should survive navigations' do
        watchdog = page.wait_for_function "() => window.__done"
        page.goto(server.empty_page).wait!
        page.goto(server.domain + 'consolelog.html').wait!
        page.evaluate_function("() => window.__done = true").wait!
        watchdog.wait!
      end
    end

    describe 'Frame#wait_for_selector' do
      let(:add_element) do
       "tag => document.body.appendChild(document.createElement(tag))"
      end

      it 'should immediately resolve promise if node exists' do
        page.goto(server.empty_page).wait!
        frame = page.main_frame
        frame.wait_for_selector('*').wait!
        frame.evaluate_function(add_element, 'div').wait!
        frame.wait_for_selector('div').wait!
      end

      it 'should work with removed MutationObserver' do
        page.evaluate_function("() => delete window.MutationObserver").wait!
        handle, _ = Concurrent::Promises.zip(
          page.wait_for_selector('.zombo'),
          page.set_content("<div class='zombo'>anything</div>")
        ).value!
        expect(page.evaluate_function("x => x.textContent", handle).value!)
          .to eq 'anything'
      end

      it 'should resolve promise when node is added' do
        page.goto(server.empty_page).wait!
        frame = page.main_frame
        watchdog = frame.wait_for_selector 'div'
        frame.evaluate_function(add_element, 'br').wait!
        frame.evaluate_function(add_element, 'div').wait!
        element_handle = watchdog.value!
        tag_name = element_handle.get_property('tagName').json_value
        expect(tag_name).to eq 'DIV'
      end

      it 'should work when node is added through innerHTML' do
        page.goto(server.empty_page).wait!
        watchdog = page.wait_for_selector 'h3 div'
        page.evaluate_function(add_element, 'span').wait!
        page.evaluate_function("() => document.querySelector('span').innerHTML = '<h3><div></div></h3>'").wait!
        watchdog.wait!
      end

      it 'Page#wait_for_selector is shortcut for main frame' do
        page.goto(server.empty_page).wait!
        attach_frame(page, 'frame1', server.empty_page).wait!
        other_frame = page.frames[1]
        watchdog = page.wait_for_selector 'div'
        other_frame.evaluate_function(add_element, 'div').wait!
        page.evaluate_function(add_element, 'div').wait!
        element_handle = watchdog.value!
        expect(element_handle.execution_context.frame).to eq page.main_frame
      end

      it 'should run in specified frame' do
        attach_frame(page, 'frame1', server.empty_page).wait!
        attach_frame(page, 'frame2', server.empty_page).wait!
        frame1 = page.frames[1]
        frame2 = page.frames[2]
        wait_for_selector_promise = frame2.wait_for_selector 'div'
        frame1.evaluate_function(add_element, 'div').wait!
        frame2.evaluate_function(add_element, 'div').wait!
        element_handle = wait_for_selector_promise.value!
        expect(element_handle.execution_context.frame).to eq frame2
      end

      it 'should throw when frame is detached' do
        attach_frame(page, 'frame1', server.empty_page).wait!
        frame = page.frames[1]
        wait_promise = frame.wait_for_selector('.box');
        detach_frame page, 'frame1'
        expect { wait_promise.value! }
          .to raise_error(/wait_for_function failed: frame got detached./)
      end

      it 'should survive cross-process navigation' do
        box_found = false
        wait_for_selector = page.wait_for_selector('.box').then { box_found = true }
        page.goto(server.empty_page).wait!
        expect(box_found).to eq false
        page.reload.wait!
        expect(box_found).to eq false
        page.goto(server.cross_process_domain + 'grid.html').wait!
        wait_for_selector.wait!
        expect(box_found).to eq true
      end

      it 'should wait for visible' do
        div_found = false
        wait_for_selector = page.wait_for_selector('div', visible: true).then { div_found = true }
        page.set_content("<div style='display: none; visibility: hidden;'>1</div>").wait!
        expect(div_found).to eq false
        page.evaluate_function("() => document.querySelector('div').style.removeProperty('display')").wait!
        expect(div_found).to eq false
        page.evaluate_function("() => document.querySelector('div').style.removeProperty('visibility')").wait!
        expect(wait_for_selector.value!).to eq true
        expect(div_found).to eq true
      end

      it 'should wait for visible recursively' do
        div_visisble = false
        wait_for_selector = page.wait_for_selector('div#inner', visible: true).then { div_visisble = true }
        page.set_content("<div style='display: none; visibility: hidden;'><div id='inner'>hi</div></div>").value!
        expect(div_visisble).to eq false
        page.evaluate_function("() => document.querySelector('div').style.removeProperty('display')").wait!
        expect(div_visisble).to eq false
        page.evaluate_function("() => document.querySelector('div').style.removeProperty('visibility')").wait!
        expect(wait_for_selector.value!).to eq true
        expect(div_visisble).to eq true
      end

      it 'hidden should wait for visibility: hidden' do
        div_hidden = false
        page.set_content("<div style='display: block;'></div>").wait!
        wait_for_selector = page.wait_for_selector('div', hidden: true).then { div_hidden = true }
        page.wait_for_selector('div').wait! # do a round trip
        expect(div_hidden).to eq false
        page.evaluate_function("() => document.querySelector('div').style.setProperty('visibility', 'hidden')").wait!
        expect(wait_for_selector.value!).to eq true
        expect(div_hidden).to eq true
      end

      it 'hidden should wait for display: none' do
        div_hidden = false
        page.set_content("<div style='display: block;'></div>").wait!
        wait_for_selector = page.wait_for_selector('div', hidden: true).then { div_hidden = true }
        page.wait_for_selector('div').wait! # do a round trip
        expect(div_hidden).to eq false
        page.evaluate_function("() => document.querySelector('div').style.setProperty('display', 'none')").wait!
        expect(wait_for_selector.value!).to eq true
        expect(div_hidden).to eq true
      end

      it 'hidden should wait for removal' do
        page.set_content("<div></div>").wait!
        div_removed = false
        wait_for_selector = page.wait_for_selector('div', hidden: true).then { div_removed = true }
        page.wait_for_selector('div').wait! # do a round trip
        expect(div_removed).to eq false
        page.evaluate_function("() => document.querySelector('div').remove()").wait!
        expect(wait_for_selector.value!).to eq true
        expect(div_removed).to eq true
      end

      it 'should return null if waiting to hide non-existing element' do
        handle = page.wait_for_selector('non-existing', hidden: true).value!
        expect(handle).to eq nil
      end

      it 'should respect timeout' do
        expect { page.wait_for_selector('div', timeout: 0.1).value! }
          .to raise_error Errors::TimeoutError, /waiting for selector "div" failed: timeout/
      end

      it 'should have an error message specifically for awaiting an element to be hidden' do
        page.set_content("<div></div>").wait!

        expect { page.wait_for_selector('div', hidden: true, timeout: 0.5).wait! }
          .to raise_error(/waiting for selector "div" to be hidden failed: timeout/)
      end

      it 'should respond to node attribute mutation' do
        div_found = false
        wait_for_selector = page.wait_for_selector('.zombo').then { div_found = true }
        page.set_content("<div class='notZombo'></div>").wait!
        expect(div_found).to eq false
        page.evaluate_function("() => document.querySelector('div').className = 'zombo'").wait!
        expect(wait_for_selector.value!).to eq true
      end

      it 'should return the element handle' do
        wait_for_selector = page.wait_for_selector '.zombo'
        page.set_content("<div class='zombo'>anything</div>").wait!
        expect(page.evaluate_function("x => x.textContent", wait_for_selector.value!).value!).to eq 'anything'
      end

      xit 'should have correct stack trace for timeout' do
        # TODO
        error = nil
        page.wait_for_selector('.zombo', timeout: 10).rescue { |e| error = e }.value!
        expect(error.backtracke).to include 'waittask.spec.js'
      end
    end

    describe 'Frame#wait_for_xpath' do
      let(:add_element) do
       "tag => document.body.appendChild(document.createElement(tag))"
      end

      it 'should support some fancy xpath' do
        page.set_content("<p>red herring</p><p>hello  world  </p>").wait!
        wait_for_xpath = page.wait_for_xpath '//p[normalize-space(.)="hello world"]'
        expect(page.evaluate_function("x => x.textContent", wait_for_xpath.value!).value!).to eq 'hello  world  '
      end

      it 'should respect timeout' do
        expect { page.wait_for_xpath('//div', timeout: 0.1).wait! }
          .to raise_error Errors::TimeoutError, %r{waiting for XPath "//div" failed: timeout}
      end

      it 'should run in specified frame' do
        attach_frame(page, 'frame1', server.empty_page).wait!
        attach_frame(page, 'frame2', server.empty_page).wait!
        frame1 = page.frames[1]
        frame2 = page.frames[2]
        wait_for_xpath_promise = frame2.wait_for_xpath '//div'
        frame1.evaluate_function(add_element, 'div').wait!
        frame2.evaluate_function(add_element, 'div').wait!
        element_handle = wait_for_xpath_promise.value!
        expect(element_handle.execution_context.frame).to eq frame2
      end

      it 'should throw when frame is detached' do
        attach_frame(page, 'frame1', server.empty_page).wait!
        frame = page.frames[1]
        wait_promise = frame.wait_for_xpath('//*[@class="box"]')
        detach_frame page, 'frame1'
        expect { wait_promise.wait! }
          .to raise_error(/wait_for_function failed: frame got detached./)
      end

      it 'hidden should wait for display: none' do
        div_hidden = false
        page.set_content("<div style='display: block;'></div>").wait!
        wait_for_xpath = page.wait_for_xpath('//div', hidden: true).then { div_hidden = true }
        page.wait_for_xpath('//div').wait! # do a round trip
        expect(div_hidden).to eq false
        page.evaluate_function("() => document.querySelector('div').style.setProperty('display', 'none')").wait!
        expect(wait_for_xpath.value!).to eq true
        expect(div_hidden).to eq true
      end

      it 'should return the element handle' do
        wait_for_xpath = page.wait_for_xpath '//*[@class="zombo"]'
        page.set_content("<div class='zombo'>anything</div>").wait!
        expect(page.evaluate_function("x => x.textContent", wait_for_xpath.value!).value!).to eq 'anything'
      end

      it 'should allow you to select a text node' do
        page.set_content("<div>some text</div>").wait!
        text = page.wait_for_xpath('//div/text()').value!
        expect(text.get_property('nodeType').json_value).to eq 3 # Node.TEXT_NODE
      end

      it 'should allow you to select an element with single slash' do
        page.set_content("<div>some text</div>").wait!
        wait_for_xpath = page.wait_for_xpath('/html/body/div').value!
        expect(page.evaluate_function("x => x.textContent", wait_for_xpath).value!).to eq 'some text'
      end
    end
  end
end
