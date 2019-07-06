module Chromiebara
  RSpec.describe WaitTask, page: true do
    describe 'Page#wait_for' do
      it 'should wait for selector' do
        pending 'todo'
        found = false
        wait_for = page.wait_for('div').then { found = true }
        page.goto server.empty_page
        expect(found).to eq false
        await page.goto server.domain + 'grid.html'
        await wait_for
        expect(found).to eq true
      end

      #it 'should wait for an xpath' do
      #  let found = false;
      #  wait_for = page.wait_for('//div').then(() => found = true);
      #  await page.goto(server.empty_page);
      #  expect(found).to eq false
      #  await page.goto(server.domain + '/grid.html');
      #  await wait_for;
      #  expect(found).to eq true
      #end
      #it 'should not allow you to select an element with single slash xpath' do
      #  await page.set_content("<div>some text</div>");
      #  let error = null;
      #  await page.wait_for('/html/body/div').catch(e => error = e);
      #  expect(error).to eqTruthy();
      #end
      #it 'should timeout' do
      #  startTime = Date.now();
      #  timeout = 42;
      #  await page.wait_for(timeout);
      #  expect(Date.now() - startTime).not.to eqLessThan(timeout / 2);
      #end
      #it 'should work with multiline body' do
      #  result = await page.wait_for_function("
      #    (() => true)()
      #  ");
      #  expect(await result.jsonValue()).to eq true
      #end
      #it 'should wait for predicate' do
      #  await Promise.all([
      #    page.wait_for(() => window.innerWidth < 100),
      #    page.setViewport({width: 10, height: 10}),
      #  ]);
      #end
      #it 'should throw when unknown type' do
      #  let error = null;
      #  await page.wait_for({foo: 'bar'}).catch(e => error = e);
      #  expect(error.message).toContain('Unsupported target type');
      #end
      #it 'should wait for predicate with arguments' do
      #  await page.wait_for((arg1, arg2) => arg1 !== arg2, {}, 1, 2);
      #end
    end

    describe 'Frame#wait_for_function' do
      it 'should accept a string' do
        watchdog = page.wait_for_function('window.__FOO === 1')
        await page.evaluate_function "() => window.__FOO = 1"
        await watchdog
      end

      it 'should work when resolved right before execution context disposal' do
        page.evaluate_on_new_document "() => window.__RELOADED = true"
        await page.wait_for_function("() => {
          if (!window.__RELOADED)
            window.location.reload();
          return true;
        }")
      end

      it 'should poll on interval' do
        pending 'what'
        success = false
        start_time = Time.now
        polling = 100
        watchdog = page.wait_for_function("() => window.__FOO === 'hit'", polling: polling)
            .then { success = true }
        await page.evaluate_function "() => window.__FOO = 'hit'"
        expect(success).to eq false
        await page.evaluate_function "() => document.body.appendChild(document.createElement('div'))"
        await watchdog
        expect(Time.now - start_time).to be >= (polling / 2)
      end

      it 'should poll on mutation' do
        success = false
        watchdog = page.wait_for_function("() => window.__FOO === 'hit'", polling: 'mutation')
            .then { success = true }
        await page.evaluate_function("() => window.__FOO = 'hit'")
        expect(success).to eq false
        await page.evaluate_function("() => document.body.appendChild(document.createElement('div'))")
        await watchdog
      end

      it 'should poll on raf' do
        watchdog = page.wait_for_function "() => window.__FOO === 'hit'", polling: 'raf'
        await page.evaluate_function "() => window.__FOO = 'hit'"
        await watchdog
      end

      #it_fails_ffox('should work with strict CSP policy' do
      #  server.setCSP('/empty.html', 'script-src ' + server.domain);
      #  await page.goto(server.empty_page);
      #  let error = null;
      #  await Promise.all([
      #    page.wait_for_function(() => window.__FOO === 'hit', {polling: 'raf'}).catch(e => error = e),
      #    page.evaluate(() => window.__FOO = 'hit')
      #  ]);
      #  expect(error).to eq null
      #end
      #it 'should throw on bad polling value' do
      #  let error = null;
      #  try {
      #    await page.wait_for_function(() => !!document.body, {polling: 'unknown'});
      #  } catch (e) {
      #    error = e;
      #  }
      #  expect(error).to eqTruthy();
      #  expect(error.message).toContain('polling');
      #end
      #it 'should throw negative polling interval' do
      #  let error = null;
      #  try {
      #    await page.wait_for_function(() => !!document.body, {polling: -10});
      #  } catch (e) {
      #    error = e;
      #  }
      #  expect(error).to eqTruthy();
      #  expect(error.message).toContain('Cannot poll with non-positive interval');
      #end
      #it 'should return the success value as a JSHandle' do
      #  expect(await (await page.wait_for_function(() => 5)).jsonValue()).to eq 5
      #end
      #it 'should return the window as a success value', async({ page }) => {
      #  expect(await page.wait_for_function(() => window)).to eqTruthy();
      #end
      #it 'should accept ElementHandle arguments' do
      #  await page.set_content('<div></div>');
      #  div = await page.$('div');
      #  let resolved = false;
      #  wait_for_function = page.wait_for_function(element => !element.parentElement, {}, div).then(() => resolved = true);
      #  expect(resolved).to eq false
      #  await page.evaluate(element => element.remove(), div);
      #  await wait_for_function;
      #end
      #it 'should respect timeout' do
      #  let error = null;
      #  await page.wait_for_function('false', {timeout: 10}).catch(e => error = e);
      #  expect(error).to eqTruthy();
      #  expect(error.message).toContain('waiting for function failed: timeout');
      #  expect(error).to eqInstanceOf(puppeteer.errors.TimeoutError);
      #end
      #it 'should respect default timeout' do
      #  page.setDefaultTimeout(1);
      #  let error = null;
      #  await page.wait_for_function('false').catch(e => error = e);
      #  expect(error).to eqInstanceOf(puppeteer.errors.TimeoutError);
      #  expect(error.message).toContain('waiting for function failed: timeout');
      #end
      #it 'should disable timeout when its set to 0' do
      #  watchdog = page.wait_for_function(() => {
      #    window.__counter = (window.__counter || 0) + 1;
      #    return window.__injected;
      #  }, {timeout: 0, polling: 10});
      #  await page.wait_for_function(() => window.__counter > 10);
      #  await page.evaluate(() => window.__injected = true);
      #  await watchdog;
      #end
      #it 'should survive cross-process navigation' do
      #  let fooFound = false;
      #  wait_for_function = page.wait_for_function('window.__FOO === 1').then(() => fooFound = true);
      #  await page.goto(server.empty_page);
      #  expect(fooFound).to eq false
      #  await page.reload();
      #  expect(fooFound).to eq false
      #  await page.goto(server.CROSS_PROCESS_domain + '/grid.html');
      #  expect(fooFound).to eq false
      #  await page.evaluate(() => window.__FOO = 1);
      #  await wait_for_function;
      #  expect(fooFound).to eq true
      #end
      #it 'should survive navigations' do
      #  watchdog = page.wait_for_function(() => window.__done);
      #  await page.goto(server.empty_page);
      #  await page.goto(server.domain + '/consolelog.html');
      #  await page.evaluate(() => window.__done = true);
      #  await watchdog;
      #end
    end

    describe 'Frame#wait_for_selector' do
      let(:add_element) do
       "tag => document.body.appendChild(document.createElement(tag))"
      end

      it 'should immediately resolve promise if node exists' do
        page.goto server.empty_page
        frame = page.main_frame
        await frame.wait_for_selector '*'
        await frame.evaluate_function add_element, 'div'
        await frame.wait_for_selector 'div'
      end

      it 'should work with removed MutationObserver' do
        await page.evaluate_function "() => delete window.MutationObserver"
        handle, _ = await Promise.all(
          page.wait_for_selector('.zombo'),
          page.set_content("<div class='zombo'>anything</div>")
        )
        expect(await page.evaluate_function("x => x.textContent", handle)).to eq 'anything'
      end

      it 'should resolve promise when node is added' do
        page.goto server.empty_page
        frame = page.main_frame
        watchdog = frame.wait_for_selector 'div'
        await frame.evaluate_function add_element, 'br'
        await frame.evaluate_function add_element, 'div'
        element_handle = await watchdog
        tag_name = element_handle.get_property('tagName').json_value
        expect(tag_name).to eq 'DIV'
      end

      it 'should work when node is added through innerHTML' do
        page.goto server.empty_page
        watchdog = page.wait_for_selector 'h3 div'
        await page.evaluate_function add_element, 'span'
        await page.evaluate_function "() => document.querySelector('span').innerHTML = '<h3><div></div></h3>'"
        await watchdog
      end

      it 'Page#wait_for_selector is shortcut for main frame' do
        page.goto server.empty_page
        attach_frame page, 'frame1', server.empty_page
        other_frame = page.frames[1]
        watchdog = page.wait_for_selector 'div'
        await other_frame.evaluate_function add_element, 'div'
        await page.evaluate_function add_element, 'div'
        element_handle = await watchdog
        expect(element_handle.execution_context.frame).to eq page.main_frame
      end

      it 'should run in specified frame' do
        attach_frame page, 'frame1', server.empty_page
        attach_frame page, 'frame2', server.empty_page
        frame1 = page.frames[1]
        frame2 = page.frames[2]
        wait_for_selector_promise = frame2.wait_for_selector 'div'
        await frame1.evaluate_function add_element, 'div'
        await frame2.evaluate_function add_element, 'div'
        element_handle = await wait_for_selector_promise
        expect(element_handle.execution_context.frame).to eq frame2
      end

      it 'should throw when frame is detached' do
        attach_frame page, 'frame1', server.empty_page
        frame = page.frames[1]
        wait_promise = frame.wait_for_selector('.box');
        detach_frame page, 'frame1'
        expect { await wait_promise }.to raise_error(/wait_for_function failed: frame got detached./)
      end

      it 'should survive cross-process navigation' do
        box_found = false
        wait_for_selector = page.wait_for_selector('.box').then { box_found = true }
        page.goto server.empty_page
        expect(box_found).to eq false
        page.reload
        expect(box_found).to eq false
        page.goto server.cross_process_domain + 'grid.html'
        await wait_for_selector
        expect(box_found).to eq true
      end

      it 'should wait for visible' do
        div_found = false
        wait_for_selector = page.wait_for_selector('div', visible: true).then { div_found = true }
        await page.set_content "<div style='display: none; visibility: hidden;'>1</div>"
        expect(div_found).to eq false
        await page.evaluate_function "() => document.querySelector('div').style.removeProperty('display')"
        expect(div_found).to eq false
        await page.evaluate_function "() => document.querySelector('div').style.removeProperty('visibility')"
        expect(await wait_for_selector).to eq true
        expect(div_found).to eq true
      end

      it 'should wait for visible recursively' do
        div_visisble = false
        wait_for_selector = page.wait_for_selector('div#inner', visible: true).then { div_visisble = true }
        await page.set_content "<div style='display: none; visibility: hidden;'><div id='inner'>hi</div></div>"
        expect(div_visisble).to eq false
        await page.evaluate_function "() => document.querySelector('div').style.removeProperty('display')"
        expect(div_visisble).to eq false
        await page.evaluate_function "() => document.querySelector('div').style.removeProperty('visibility')"
        expect(await wait_for_selector).to eq true
        expect(div_visisble).to eq true
      end

      it 'hidden should wait for visibility: hidden' do
        div_hidden = false
        await page.set_content "<div style='display: block;'></div>"
        wait_for_selector = page.wait_for_selector('div', hidden: true).then { div_hidden = true }
        await page.wait_for_selector 'div' # do a round trip
        expect(div_hidden).to eq false
        await page.evaluate_function "() => document.querySelector('div').style.setProperty('visibility', 'hidden')"
        expect(await wait_for_selector).to eq true
        expect(div_hidden).to eq true
      end

      it 'hidden should wait for display: none' do
        div_hidden = false
        await page.set_content "<div style='display: block;'></div>"
        wait_for_selector = page.wait_for_selector('div', hidden: true).then { div_hidden = true }
        await page.wait_for_selector 'div' # do a round trip
        expect(div_hidden).to eq false
        await page.evaluate_function "() => document.querySelector('div').style.setProperty('display', 'none')"
        expect(await wait_for_selector).to eq true
        expect(div_hidden).to eq true
      end

      it 'hidden should wait for removal' do
        await page.set_content "<div></div>"
        div_removed = false
        wait_for_selector = page.wait_for_selector('div', hidden: true).then { div_removed = true }
        await page.wait_for_selector 'div' # do a round trip
        expect(div_removed).to eq false
        await page.evaluate_function "() => document.querySelector('div').remove()"
        expect(await wait_for_selector).to eq true
        expect(div_removed).to eq true
      end

      it 'should return null if waiting to hide non-existing element' do
        handle = await page.wait_for_selector 'non-existing', hidden: true
        expect(handle).to eq nil
      end

      #it 'should respect timeout' do
      #  let error = null;
      #  await page.wait_for_selector('div', {timeout: 10}).catch(e => error = e);
      #  expect(error).to eqTruthy();
      #  expect(error.message).toContain('waiting for selector "div" failed: timeout');
      #  expect(error).to eqInstanceOf(puppeteer.errors.TimeoutError);
      #end

      it 'should have an error message specifically for awaiting an element to be hidden' do
        pending 'broken'
        await page.set_content "<div></div>"

        expect { await page.wait_for_selector 'div', hidden: true, timeout: 10 }
          .to raise_error(/waiting for selector "div" to be hidden failed: timeout/)
      end

      it 'should respond to node attribute mutation' do
        div_found = false
        wait_for_selector = page.wait_for_selector('.zombo').then { div_found = true }
        await page.set_content "<div class='notZombo'></div>"
        expect(div_found).to eq false
        await page.evaluate_function "() => document.querySelector('div').className = 'zombo'"
        expect(await wait_for_selector).to eq true
      end

      it 'should return the element handle' do
        wait_for_selector = page.wait_for_selector '.zombo'
        await page.set_content "<div class='zombo'>anything</div>"
        expect(await page.evaluate_function("x => x.textContent", (await wait_for_selector))).to eq 'anything'
      end

      xit 'should have correct stack trace for timeout' do
        # TODO
        error = nil
        await page.wait_for_selector('.zombo', timeout: 10).catch { |e| error = e }
        expect(error.backtracke).to include 'waittask.spec.js'
      end
    end

    describe 'Frame#wait_for_xpath' do
      let(:add_element) do
       "tag => document.body.appendChild(document.createElement(tag))"
      end

      it 'should support some fancy xpath' do
        await page.set_content "<p>red herring</p><p>hello  world  </p>"
        wait_for_xpath = page.wait_for_xpath '//p[normalize-space(.)="hello world"]'
        expect(await page.evaluate_function("x => x.textContent", (await wait_for_xpath))).to eq 'hello  world  '
      end

      # TODO
      #it 'should respect timeout' do
      #  let error = null;
      #  await page.wait_for_xpath('//div', {timeout: 10}).catch(e => error = e);
      #  expect(error).to eqTruthy();
      #  expect(error.message).toContain('waiting for XPath "//div" failed: timeout');
      #  expect(error).to eqInstanceOf(puppeteer.errors.TimeoutError);
      #end

      it 'should run in specified frame' do
        attach_frame page, 'frame1', server.empty_page
        attach_frame page, 'frame2', server.empty_page
        frame1 = page.frames[1]
        frame2 = page.frames[2]
        wait_for_xpath_promise = frame2.wait_for_xpath '//div'
        await frame1.evaluate_function add_element, 'div'
        await frame2.evaluate_function add_element, 'div'
        element_handle = await wait_for_xpath_promise
        expect(element_handle.execution_context.frame).to eq frame2
      end

      it 'should throw when frame is detached' do
        attach_frame page, 'frame1', server.empty_page
        frame = page.frames[1]
        wait_promise = frame.wait_for_xpath('//*[@class="box"]')
        detach_frame page, 'frame1'
        expect {  await wait_promise }
          .to raise_error(/wait_for_function failed: frame got detached./)
      end

      it 'hidden should wait for display: none' do
        div_hidden = false
        await page.set_content "<div style='display: block;'></div>"
        wait_for_xpath = page.wait_for_xpath('//div', hidden: true).then { div_hidden = true }
        await page.wait_for_xpath('//div') # do a round trip
        expect(div_hidden).to eq false
        await page.evaluate_function("() => document.querySelector('div').style.setProperty('display', 'none')")
        expect(await wait_for_xpath).to eq true
        expect(div_hidden).to eq true
      end

      it 'should return the element handle' do
        wait_for_xpath = page.wait_for_xpath '//*[@class="zombo"]'
        await page.set_content "<div class='zombo'>anything</div>"
        expect(await page.evaluate_function("x => x.textContent", (await wait_for_xpath))).to eq 'anything'
      end

      it 'should allow you to select a text node' do
        await page.set_content "<div>some text</div>"
        text = await page.wait_for_xpath('//div/text()');
        expect(text.get_property('nodeType').json_value).to eq 3 # Node.TEXT_NODE
      end

      it 'should allow you to select an element with single slash' do
        await page.set_content "<div>some text</div>"
        wait_for_xpath = page.wait_for_xpath '/html/body/div'
        expect(await page.evaluate_function("x => x.textContent", (await wait_for_xpath))).to eq 'some text'
      end
    end
  end
end
