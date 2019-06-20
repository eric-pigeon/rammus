module Chromiebara
  RSpec.describe WaitTask, browser: true do
    include Promise::Await
    before { @_context = browser.create_context }
    after { @_context.close }
    let(:context) { @_context }
    let!(:page) { context.new_page }

    describe 'Page#wait_for' do
      it 'should wait for selector' do
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
      #  const wait_for = page.wait_for('//div').then(() => found = true);
      #  await page.goto(server.EMPTY_PAGE);
      #  expect(found).to eq false
      #  await page.goto(server.domain + '/grid.html');
      #  await wait_for;
      #  expect(found).to eq true
      #end
      #it 'should not allow you to select an element with single slash xpath' do
      #  await page.set_content(`<div>some text</div>`);
      #  let error = null;
      #  await page.wait_for('/html/body/div').catch(e => error = e);
      #  expect(error).to eqTruthy();
      #end
      #it 'should timeout' do
      #  const startTime = Date.now();
      #  const timeout = 42;
      #  await page.wait_for(timeout);
      #  expect(Date.now() - startTime).not.to eqLessThan(timeout / 2);
      #end
      #it 'should work with multiline body' do
      #  const result = await page.wait_forFunction(`
      #    (() => true)()
      #  `);
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
      #it 'should accept a string' do
      #  const watchdog = page.wait_forFunction('window.__FOO === 1');
      #  await page.evaluate(() => window.__FOO = 1);
      #  await watchdog;
      #end
      #it 'should work when resolved right before execution context disposal' do
      #  await page.evaluateOnNewDocument(() => window.__RELOADED = true);
      #  await page.wait_forFunction(() => {
      #    if (!window.__RELOADED)
      #      window.location.reload();
      #    return true;
      #  });
      #end
      #it 'should poll on interval' do
      #  let success = false;
      #  const startTime = Date.now();
      #  const polling = 100;
      #  const watchdog = page.wait_forFunction(() => window.__FOO === 'hit', {polling})
      #      .then(() => success = true);
      #  await page.evaluate(() => window.__FOO = 'hit');
      #  expect(success).to eq false
      #  await page.evaluate(() => document.body.appendChild(document.createElement('div')));
      #  await watchdog;
      #  expect(Date.now() - startTime).not.to eqLessThan(polling / 2);
      #end
      #it 'should poll on mutation' do
      #  let success = false;
      #  const watchdog = page.wait_forFunction(() => window.__FOO === 'hit', {polling: 'mutation'})
      #      .then(() => success = true);
      #  await page.evaluate(() => window.__FOO = 'hit');
      #  expect(success).to eq false
      #  await page.evaluate(() => document.body.appendChild(document.createElement('div')));
      #  await watchdog;
      #end
      #it 'should poll on raf' do
      #  const watchdog = page.wait_forFunction(() => window.__FOO === 'hit', {polling: 'raf'});
      #  await page.evaluate(() => window.__FOO = 'hit');
      #  await watchdog;
      #end
      #it_fails_ffox('should work with strict CSP policy' do
      #  server.setCSP('/empty.html', 'script-src ' + server.domain);
      #  await page.goto(server.EMPTY_PAGE);
      #  let error = null;
      #  await Promise.all([
      #    page.wait_forFunction(() => window.__FOO === 'hit', {polling: 'raf'}).catch(e => error = e),
      #    page.evaluate(() => window.__FOO = 'hit')
      #  ]);
      #  expect(error).to eq null
      #end
      #it 'should throw on bad polling value' do
      #  let error = null;
      #  try {
      #    await page.wait_forFunction(() => !!document.body, {polling: 'unknown'});
      #  } catch (e) {
      #    error = e;
      #  }
      #  expect(error).to eqTruthy();
      #  expect(error.message).toContain('polling');
      #end
      #it 'should throw negative polling interval' do
      #  let error = null;
      #  try {
      #    await page.wait_forFunction(() => !!document.body, {polling: -10});
      #  } catch (e) {
      #    error = e;
      #  }
      #  expect(error).to eqTruthy();
      #  expect(error.message).toContain('Cannot poll with non-positive interval');
      #end
      #it 'should return the success value as a JSHandle' do
      #  expect(await (await page.wait_forFunction(() => 5)).jsonValue()).to eq 5
      #end
      #it 'should return the window as a success value', async({ page }) => {
      #  expect(await page.wait_forFunction(() => window)).to eqTruthy();
      #end
      #it 'should accept ElementHandle arguments' do
      #  await page.set_content('<div></div>');
      #  const div = await page.$('div');
      #  let resolved = false;
      #  const wait_forFunction = page.wait_forFunction(element => !element.parentElement, {}, div).then(() => resolved = true);
      #  expect(resolved).to eq false
      #  await page.evaluate(element => element.remove(), div);
      #  await wait_forFunction;
      #end
      #it 'should respect timeout' do
      #  let error = null;
      #  await page.wait_forFunction('false', {timeout: 10}).catch(e => error = e);
      #  expect(error).to eqTruthy();
      #  expect(error.message).toContain('waiting for function failed: timeout');
      #  expect(error).to eqInstanceOf(puppeteer.errors.TimeoutError);
      #end
      #it 'should respect default timeout' do
      #  page.setDefaultTimeout(1);
      #  let error = null;
      #  await page.wait_forFunction('false').catch(e => error = e);
      #  expect(error).to eqInstanceOf(puppeteer.errors.TimeoutError);
      #  expect(error.message).toContain('waiting for function failed: timeout');
      #end
      #it 'should disable timeout when its set to 0' do
      #  const watchdog = page.wait_forFunction(() => {
      #    window.__counter = (window.__counter || 0) + 1;
      #    return window.__injected;
      #  }, {timeout: 0, polling: 10});
      #  await page.wait_forFunction(() => window.__counter > 10);
      #  await page.evaluate(() => window.__injected = true);
      #  await watchdog;
      #end
      #it 'should survive cross-process navigation' do
      #  let fooFound = false;
      #  const wait_forFunction = page.wait_forFunction('window.__FOO === 1').then(() => fooFound = true);
      #  await page.goto(server.EMPTY_PAGE);
      #  expect(fooFound).to eq false
      #  await page.reload();
      #  expect(fooFound).to eq false
      #  await page.goto(server.CROSS_PROCESS_domain + '/grid.html');
      #  expect(fooFound).to eq false
      #  await page.evaluate(() => window.__FOO = 1);
      #  await wait_forFunction;
      #  expect(fooFound).to eq true
      #end
      #it 'should survive navigations' do
      #  const watchdog = page.wait_forFunction(() => window.__done);
      #  await page.goto(server.EMPTY_PAGE);
      #  await page.goto(server.domain + '/consolelog.html');
      #  await page.evaluate(() => window.__done = true);
      #  await watchdog;
      #end
    end

    describe 'Frame#wait_for_selector' do
      #const addElement = tag => document.body.appendChild(document.createElement(tag));

      #it 'should immediately resolve promise if node exists' do
      #  await page.goto(server.EMPTY_PAGE);
      #  const frame = page.mainFrame();
      #  await frame.wait_forSelector('*');
      #  await frame.evaluate(addElement, 'div');
      #  await frame.wait_forSelector('div');
      #end

      #it_fails_ffox('should work with removed MutationObserver' do
      #  await page.evaluate(() => delete window.MutationObserver);
      #  const [handle] = await Promise.all([
      #    page.wait_forSelector('.zombo'),
      #    page.set_content(`<div class='zombo'>anything</div>`),
      #  ]);
      #  expect(await page.evaluate(x => x.textContent, handle)).to eq 'anything'
      #end

      #it 'should resolve promise when node is added' do
      #  await page.goto(server.EMPTY_PAGE);
      #  const frame = page.mainFrame();
      #  const watchdog = frame.wait_forSelector('div');
      #  await frame.evaluate(addElement, 'br');
      #  await frame.evaluate(addElement, 'div');
      #  const eHandle = await watchdog;
      #  const tagName = await eHandle.getProperty('tagName').then(e => e.jsonValue());
      #  expect(tagName).to eq 'DIV'
      #end

      #it 'should work when node is added through innerHTML' do
      #  await page.goto(server.EMPTY_PAGE);
      #  const watchdog = page.wait_forSelector('h3 div');
      #  await page.evaluate(addElement, 'span');
      #  await page.evaluate(() => document.querySelector('span').innerHTML = '<h3><div></div></h3>');
      #  await watchdog;
      #end

      #it 'Page.wait_forSelector is shortcut for main frame' do
      #  await page.goto(server.EMPTY_PAGE);
      #  await utils.attachFrame(page, 'frame1', server.EMPTY_PAGE);
      #  const otherFrame = page.frames()[1];
      #  const watchdog = page.wait_forSelector('div');
      #  await otherFrame.evaluate(addElement, 'div');
      #  await page.evaluate(addElement, 'div');
      #  const eHandle = await watchdog;
      #  expect(eHandle.executionContext().frame()).to eq page.mainFrame()
      #end

      #it 'should run in specified frame' do
      #  await utils.attachFrame(page, 'frame1', server.EMPTY_PAGE);
      #  await utils.attachFrame(page, 'frame2', server.EMPTY_PAGE);
      #  const frame1 = page.frames()[1];
      #  const frame2 = page.frames()[2];
      #  const wait_forSelectorPromise = frame2.wait_forSelector('div');
      #  await frame1.evaluate(addElement, 'div');
      #  await frame2.evaluate(addElement, 'div');
      #  const eHandle = await wait_forSelectorPromise;
      #  expect(eHandle.executionContext().frame()).to eq frame2
      #end

      #it 'should throw when frame is detached' do
      #  await utils.attachFrame(page, 'frame1', server.EMPTY_PAGE);
      #  const frame = page.frames()[1];
      #  let waitError = null;
      #  const waitPromise = frame.wait_forSelector('.box').catch(e => waitError = e);
      #  await utils.detachFrame(page, 'frame1');
      #  await waitPromise;
      #  expect(waitError).to eqTruthy();
      #  expect(waitError.message).toContain('wait_forFunction failed: frame got detached.');
      #end
      #it 'should survive cross-process navigation' do
      #  let boxFound = false;
      #  const wait_forSelector = page.wait_forSelector('.box').then(() => boxFound = true);
      #  await page.goto(server.EMPTY_PAGE);
      #  expect(boxFound).to eq false
      #  await page.reload();
      #  expect(boxFound).to eq false
      #  await page.goto(server.CROSS_PROCESS_domain + '/grid.html');
      #  await wait_forSelector;
      #  expect(boxFound).to eq true
      #end
      #it 'should wait for visible' do
      #  let divFound = false;
      #  const wait_forSelector = page.wait_forSelector('div', {visible: true}).then(() => divFound = true);
      #  await page.set_content(`<div style='display: none; visibility: hidden;'>1</div>`);
      #  expect(divFound).to eq false
      #  await page.evaluate(() => document.querySelector('div').style.removeProperty('display'));
      #  expect(divFound).to eq false
      #  await page.evaluate(() => document.querySelector('div').style.removeProperty('visibility'));
      #  expect(await wait_forSelector).to eq true
      #  expect(divFound).to eq true
      #end
      #it 'should wait for visible recursively' do
      #  let divVisible = false;
      #  const wait_forSelector = page.wait_forSelector('div#inner', {visible: true}).then(() => divVisible = true);
      #  await page.set_content(`<div style='display: none; visibility: hidden;'><div id="inner">hi</div></div>`);
      #  expect(divVisible).to eq false
      #  await page.evaluate(() => document.querySelector('div').style.removeProperty('display'));
      #  expect(divVisible).to eq false
      #  await page.evaluate(() => document.querySelector('div').style.removeProperty('visibility'));
      #  expect(await wait_forSelector).to eq true
      #  expect(divVisible).to eq true
      #end
      #it 'hidden should wait for visibility: hidden' do
      #  let divHidden = false;
      #  await page.set_content(`<div style='display: block;'></div>`);
      #  const wait_forSelector = page.wait_forSelector('div', {hidden: true}).then(() => divHidden = true);
      #  await page.wait_forSelector('div'); // do a round trip
      #  expect(divHidden).to eq false
      #  await page.evaluate(() => document.querySelector('div').style.setProperty('visibility', 'hidden'));
      #  expect(await wait_forSelector).to eq true
      #  expect(divHidden).to eq true
      #end
      #it 'hidden should wait for display: none' do
      #  let divHidden = false;
      #  await page.set_content(`<div style='display: block;'></div>`);
      #  const wait_forSelector = page.wait_forSelector('div', {hidden: true}).then(() => divHidden = true);
      #  await page.wait_forSelector('div'); // do a round trip
      #  expect(divHidden).to eq false
      #  await page.evaluate(() => document.querySelector('div').style.setProperty('display', 'none'));
      #  expect(await wait_forSelector).to eq true
      #  expect(divHidden).to eq true
      #end
      #it 'hidden should wait for removal' do
      #  await page.set_content(`<div></div>`);
      #  let divRemoved = false;
      #  const wait_forSelector = page.wait_forSelector('div', {hidden: true}).then(() => divRemoved = true);
      #  await page.wait_forSelector('div'); // do a round trip
      #  expect(divRemoved).to eq false
      #  await page.evaluate(() => document.querySelector('div').remove());
      #  expect(await wait_forSelector).to eq true
      #  expect(divRemoved).to eq true
      #end
      #it 'should return null if waiting to hide non-existing element' do
      #  const handle = await page.wait_forSelector('non-existing', { hidden: true });
      #  expect(handle).to eq null
      #end
      #it 'should respect timeout' do
      #  let error = null;
      #  await page.wait_forSelector('div', {timeout: 10}).catch(e => error = e);
      #  expect(error).to eqTruthy();
      #  expect(error.message).toContain('waiting for selector "div" failed: timeout');
      #  expect(error).to eqInstanceOf(puppeteer.errors.TimeoutError);
      #end
      #it 'should have an error message specifically for awaiting an element to be hidden' do
      #  await page.set_content(`<div></div>`);
      #  let error = null;
      #  await page.wait_forSelector('div', {hidden: true, timeout: 10}).catch(e => error = e);
      #  expect(error).to eqTruthy();
      #  expect(error.message).toContain('waiting for selector "div" to be hidden failed: timeout');
      #end

      #it 'should respond to node attribute mutation' do
      #  let divFound = false;
      #  const wait_forSelector = page.wait_forSelector('.zombo').then(() => divFound = true);
      #  await page.set_content(`<div class='notZombo'></div>`);
      #  expect(divFound).to eq false
      #  await page.evaluate(() => document.querySelector('div').className = 'zombo');
      #  expect(await wait_forSelector).to eq true
      #end
      #it 'should return the element handle' do
      #  const wait_forSelector = page.wait_forSelector('.zombo');
      #  await page.set_content(`<div class='zombo'>anything</div>`);
      #  expect(await page.evaluate(x => x.textContent, await wait_forSelector)).to eq 'anything'
      #end
      #(asyncawait ? it : xit)('should have correct stack trace for timeout' do
      #  let error;
      #  await page.wait_forSelector('.zombo', {timeout: 10}).catch(e => error = e);
      #  expect(error.stack).toContain('waittask.spec.js');
      #end
    end

    describe 'Frame#wait_for_xPath' do
      #const addElement = tag => document.body.appendChild(document.createElement(tag));

      it 'should support some fancy xpath' do
        page.set_content "<p>red herring</p><p>hello  world  </p>"
        wait_for_xpath = page.wait_for_xpath '//p[normalize-space(.)="hello world"]'
        expect(page.evaluate_function("x => x.textContent", (await wait_for_xpath))).to eq 'hello  world  '
      end

      #it 'should respect timeout' do
      #  let error = null;
      #  await page.wait_for_xpath('//div', {timeout: 10}).catch(e => error = e);
      #  expect(error).to eqTruthy();
      #  expect(error.message).toContain('waiting for XPath "//div" failed: timeout');
      #  expect(error).to eqInstanceOf(puppeteer.errors.TimeoutError);
      #end
      #it 'should run in specified frame' do
      #  await utils.attachFrame(page, 'frame1', server.EMPTY_PAGE);
      #  await utils.attachFrame(page, 'frame2', server.EMPTY_PAGE);
      #  const frame1 = page.frames()[1];
      #  const frame2 = page.frames()[2];
      #  const wait_for_xpathPromise = frame2.wait_for_xpath('//div');
      #  await frame1.evaluate(addElement, 'div');
      #  await frame2.evaluate(addElement, 'div');
      #  const eHandle = await wait_for_xpathPromise;
      #  expect(eHandle.executionContext().frame()).to eq frame2
      #end
      #it 'should throw when frame is detached' do
      #  await utils.attachFrame(page, 'frame1', server.EMPTY_PAGE);
      #  const frame = page.frames()[1];
      #  let waitError = null;
      #  const waitPromise = frame.wait_for_xpath('//*[@class="box"]').catch(e => waitError = e);
      #  await utils.detachFrame(page, 'frame1');
      #  await waitPromise;
      #  expect(waitError).to eqTruthy();
      #  expect(waitError.message).toContain('wait_forFunction failed: frame got detached.');
      #end
      #it 'hidden should wait for display: none' do
      #  let divHidden = false;
      #  await page.set_content(`<div style='display: block;'></div>`);
      #  const wait_for_xpath = page.wait_for_xpath('//div', {hidden: true}).then(() => divHidden = true);
      #  await page.wait_for_xpath('//div'); // do a round trip
      #  expect(divHidden).to eq false
      #  await page.evaluate(() => document.querySelector('div').style.setProperty('display', 'none'));
      #  expect(await wait_for_xpath).to eq true
      #  expect(divHidden).to eq true
      #end
      #it 'should return the element handle' do
      #  const wait_for_xpath = page.wait_for_xpath('//*[@class="zombo"]');
      #  await page.set_content(`<div class='zombo'>anything</div>`);
      #  expect(await page.evaluate(x => x.textContent, await wait_for_xpath)).to eq 'anything'
      #end
      #it 'should allow you to select a text node' do
      #  await page.set_content(`<div>some text</div>`);
      #  const text = await page.wait_for_xpath('//div/text()');
      #  expect(await (await text.getProperty('nodeType')).jsonValue()).to eq 3 /* Node.TEXT_NODE */
      #end
      #it 'should allow you to select an element with single slash' do
      #  await page.set_content(`<div>some text</div>`);
      #  const wait_for_xpath = page.wait_for_xpath('/html/body/div');
      #  expect(await page.evaluate(x => x.textContent, await wait_for_xpath)).to eq 'some text'
      #end
    end
  end
end
