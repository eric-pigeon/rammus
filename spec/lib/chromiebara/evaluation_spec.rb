module Chromiebara
  RSpec.describe 'Evaluation', browser: true do
    before { @_context = browser.create_context }
    after { @_context.close }
    let(:context) { @_context }
    let!(:page) { context.new_page }

    describe 'Page#evaluate_function' do
      #it('should work', async({page, server}) => {
      #  const result = await page.evaluate(() => 7 * 3);
      #  expect(result).toBe(21);
      #});
      #(bigint ? it : xit)('should transfer BigInt', async({page, server}) => {
      #  const result = await page.evaluate(a => a, BigInt(42));
      #  expect(result).toBe(BigInt(42));
      #});
      #it('should transfer NaN', async({page, server}) => {
      #  const result = await page.evaluate(a => a, NaN);
      #  expect(Object.is(result, NaN)).toBe(true);
      #});
      #it('should transfer -0', async({page, server}) => {
      #  const result = await page.evaluate(a => a, -0);
      #  expect(Object.is(result, -0)).toBe(true);
      #});
      #it('should transfer Infinity', async({page, server}) => {
      #  const result = await page.evaluate(a => a, Infinity);
      #  expect(Object.is(result, Infinity)).toBe(true);
      #});
      #it('should transfer -Infinity', async({page, server}) => {
      #  const result = await page.evaluate(a => a, -Infinity);
      #  expect(Object.is(result, -Infinity)).toBe(true);
      #});
      #it('should transfer arrays', async({page, server}) => {
      #  const result = await page.evaluate(a => a, [1, 2, 3]);
      #  expect(result).toEqual([1,2,3]);
      #});
      #it('should transfer arrays as arrays, not objects', async({page, server}) => {
      #  const result = await page.evaluate(a => Array.isArray(a), [1, 2, 3]);
      #  expect(result).toBe(true);
      #});
      #it('should modify global environment', async({page}) => {
      #  await page.evaluate(() => window.globalVar = 123);
      #  expect(await page.evaluate('globalVar')).toBe(123);
      #});
      #it('should evaluate in the page context', async({page, server}) => {
      #  await page.goto(server.PREFIX + '/global-var.html');
      #  expect(await page.evaluate('globalVar')).toBe(123);
      #});
      #it_fails_ffox('should return undefined for objects with symbols', async({page, server}) => {
      #  expect(await page.evaluate(() => [Symbol('foo4')])).toBe(undefined);
      #});
      #(asyncawait ? it : xit)('should work with function shorthands', async({page, server}) => {
      #  // trick node6 transpiler to not touch our object.
      #  // TODO(lushnikov): remove eval once Node6 is dropped.
      #  const a = eval(`({
      #    sum(a, b) { return a + b; },

      #    async mult(a, b) { return a * b; }
      #  })`);
      #  expect(await page.evaluate(a.sum, 1, 2)).toBe(3);
      #  expect(await page.evaluate(a.mult, 2, 4)).toBe(8);
      #});
      #it('should work with unicode chars', async({page, server}) => {
      #  const result = await page.evaluate(a => a['中文字符'], {'中文字符': 42});
      #  expect(result).toBe(42);
      #});
      #it('should throw when evaluation triggers reload', async({page, server}) => {
      #  let error = null;
      #  await page.evaluate(() => {
      #    location.reload();
      #    return new Promise(() => {});
      #  }).catch(e => error = e);
      #  expect(error.message).toContain('Protocol error');
      #});
      #it('should await promise', async({page, server}) => {
      #  const result = await page.evaluate(() => Promise.resolve(8 * 7));
      #  expect(result).toBe(56);
      #});
      #it('should work right after framenavigated', async({page, server}) => {
      #  let frameEvaluation = null;
      #  page.on('framenavigated', async frame => {
      #    frameEvaluation = frame.evaluate(() => 6 * 7);
      #  });
      #  await page.goto(server.EMPTY_PAGE);
      #  expect(await frameEvaluation).toBe(42);
      #});
      #it('should work from-inside an exposed function', async({page, server}) => {
      #  // Setup inpage callback, which calls Page.evaluate
      #  await page.exposeFunction('callController', async function(a, b) {
      #    return await page.evaluate((a, b) => a * b, a, b);
      #  });
      #  const result = await page.evaluate(async function() {
      #    return await callController(9, 3);
      #  });
      #  expect(result).toBe(27);
      #});
      #it('should reject promise with exception', async({page, server}) => {
      #  let error = null;
      #  await page.evaluate(() => not.existing.object.property).catch(e => error = e);
      #  expect(error).toBeTruthy();
      #  expect(error.message).toContain('not is not defined');
      #});
      #it('should support thrown strings as error messages', async({page, server}) => {
      #  let error = null;
      #  await page.evaluate(() => { throw 'qwerty'; }).catch(e => error = e);
      #  expect(error).toBeTruthy();
      #  expect(error.message).toContain('qwerty');
      #});
      #it('should support thrown numbers as error messages', async({page, server}) => {
      #  let error = null;
      #  await page.evaluate(() => { throw 100500; }).catch(e => error = e);
      #  expect(error).toBeTruthy();
      #  expect(error.message).toContain('100500');
      #});
      #it('should return complex objects', async({page, server}) => {
      #  const object = {foo: 'bar!'};
      #  const result = await page.evaluate(a => a, object);
      #  expect(result).not.toBe(object);
      #  expect(result).toEqual(object);
      #});
      #(bigint ? it : xit)('should return BigInt', async({page, server}) => {
      #  const result = await page.evaluate(() => BigInt(42));
      #  expect(result).toBe(BigInt(42));
      #});
      #it('should return NaN', async({page, server}) => {
      #  const result = await page.evaluate(() => NaN);
      #  expect(Object.is(result, NaN)).toBe(true);
      #});
      #it('should return -0', async({page, server}) => {
      #  const result = await page.evaluate(() => -0);
      #  expect(Object.is(result, -0)).toBe(true);
      #});
      #it('should return Infinity', async({page, server}) => {
      #  const result = await page.evaluate(() => Infinity);
      #  expect(Object.is(result, Infinity)).toBe(true);
      #});
      #it('should return -Infinity', async({page, server}) => {
      #  const result = await page.evaluate(() => -Infinity);
      #  expect(Object.is(result, -Infinity)).toBe(true);
      #});
      #it('should accept "undefined" as one of multiple parameters', async({page, server}) => {
      #  const result = await page.evaluate((a, b) => Object.is(a, undefined) && Object.is(b, 'foo'), undefined, 'foo');
      #  expect(result).toBe(true);
      #});
      #it('should properly serialize null fields', async({page}) => {
      #  expect(await page.evaluate(() => ({a: undefined}))).toEqual({});
      #});
      #it('should return undefined for non-serializable objects', async({page, server}) => {
      #  expect(await page.evaluate(() => window)).toBe(undefined);
      #});
      #it('should fail for circular object', async({page, server}) => {
      #  const result = await page.evaluate(() => {
      #    const a = {};
      #    const b = {a};
      #    a.b = b;
      #    return a;
      #  });
      #  expect(result).toBe(undefined);
      #});
      #it_fails_ffox('should be able to throw a tricky error', async({page, server}) => {
      #  const windowHandle = await page.evaluateHandle(() => window);
      #  const errorText = await windowHandle.jsonValue().catch(e => e.message);
      #  const error = await page.evaluate(errorText => {
      #    throw new Error(errorText);
      #  }, errorText).catch(e => e);
      #  expect(error.message).toContain(errorText);
      #});
      #it('should accept a string', async({page, server}) => {
      #  const result = await page.evaluate('1 + 2');
      #  expect(result).toBe(3);
      #});
      #it('should accept a string with semi colons', async({page, server}) => {
      #  const result = await page.evaluate('1 + 5;');
      #  expect(result).toBe(6);
      #});
      #it('should accept a string with comments', async({page, server}) => {
      #  const result = await page.evaluate('2 + 5;\n// do some math!');
      #  expect(result).toBe(7);
      #});
      #it('should accept element handle as an argument', async({page, server}) => {
      #  await page.setContent('<section>42</section>');
      #  const element = await page.$('section');
      #  const text = await page.evaluate(e => e.textContent, element);
      #  expect(text).toBe('42');
      #});
      #it('should throw if underlying element was disposed', async({page, server}) => {
      #  await page.setContent('<section>39</section>');
      #  const element = await page.$('section');
      #  expect(element).toBeTruthy();
      #  await element.dispose();
      #  let error = null;
      #  await page.evaluate(e => e.textContent, element).catch(e => error = e);
      #  expect(error.message).toContain('JSHandle is disposed');
      #});
      #it('should throw if elementHandles are from other frames', async({page, server}) => {
      #  await utils.attachFrame(page, 'frame1', server.EMPTY_PAGE);
      #  const bodyHandle = await page.frames()[1].$('body');
      #  let error = null;
      #  await page.evaluate(body => body.innerHTML, bodyHandle).catch(e => error = e);
      #  expect(error).toBeTruthy();
      #  expect(error.message).toContain('JSHandles can be evaluated only in the context they were created');
      #});
      #it('should simulate a user gesture', async({page, server}) => {
      #  const result = await page.evaluate(() => document.execCommand('copy'));
      #  expect(result).toBe(true);
      #});
      #it('should throw a nice error after a navigation', async({page, server}) => {
      #  const executionContext = await page.mainFrame().executionContext();

      #  await Promise.all([
      #    page.waitForNavigation(),
      #    executionContext.evaluate(() => window.location.reload())
      #  ]);
      #  const error = await executionContext.evaluate(() => null).catch(e => e);
      #  expect(error.message).toContain('navigation');
      #});

      it 'should not throw an error when evaluation does a navigation' do
        page.goto server.domain + 'one-style.html'
        result = page.evaluate_function "() => {
          window.location = '/empty.html';
          return [42];
        }"
        expect(result).to eq [42]
      end
    end

    describe 'Page#evaluate_on_new_document' do
      it 'should evaluate before anything else on the page' do
        page.evaluate_on_new_document "function(){ window.injected = 123; }"
        page.goto server.domain + 'tamperable.html'
        expect(page.evaluate_function "() => window.result").to eq 123
      end

      it 'should work with CSP' do
        server.set_content_security_policy '/empty.html', 'script-src ' + server.domain
        page.evaluate_on_new_document "function() { window.injected = 123; }"
        page.goto server.domain + 'empty.html'
        expect(page.evaluate_function "() => window.injected").to eq 123

        # Make sure CSP works.
        page.add_script_tag(content: 'window.e = 10;')
        expect(page.evaluate_function '() => window.e').to be nil
      end
    end

    describe 'Frame#evaluate_function' do
      it 'should have different execution contexts' do
        page.goto server.empty_page
        attach_frame page, 'frame1', server.empty_page
        expect(page.frames.length).to eq 2
        page.frames[0].evaluate_function "() => window.FOO = 'foo'"
        page.frames[1].evaluate_function "() => window.FOO = 'bar'"
        expect(page.frames[0].evaluate_function "() => window.FOO").to eq 'foo'
        expect(page.frames[1].evaluate_function "() => window.FOO").to eq 'bar'
      end

      it 'should have correct execution contexts' do
        page.goto server.domain + 'frames/one-frame.html'
        expect(page.frames.length).to eq 2
        expect(page.frames[0].evaluate_function '() => document.body.textContent.trim()').to eq ''
        expect(page.frames[1].evaluate_function '() => document.body.textContent.trim()').to eq "Hi, I'm frame"
      end

      it 'should execute after cross-site navigation' do
        page.goto server.empty_page
        main_frame = page.main_frame
        expect(main_frame.evaluate_function '() => window.location.href').to include 'localhost'
        page.goto server.cross_process_domain + 'empty.html'
        expect(main_frame.evaluate_function '() => window.location.href').to include '127'
      end
    end
  end
end
