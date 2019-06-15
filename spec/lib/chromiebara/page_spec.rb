module Chromiebara
  RSpec.describe Page, browser: true do
    before { @_context = browser.create_context }
    after { @_context.close }
    let(:context) { @_context }
    let!(:page) { context.new_page }

    describe '#close' do
      it 'should not be visible in browser.pages' do
        new_page = browser.new_page
        expect(browser.pages).to include new_page

        new_page.close
        expect(browser.pages).not_to include new_page
      end
    end

    describe '#evaluate' do
      context 'passing javascript function' do
        it 'transfers NaN' do
          result = page.evaluate_function 'a => a', 'NaN'
          expect(result).to eq 'NaN'
        end

        it 'transfers -0' do
          result = page.evaluate_function 'a => a', -0
          expect(result).to eq 0
        end

        it 'should transfer Float::INFINITY' do
          result = page.evaluate_function 'a => a', Float::INFINITY
          expect(result).to eq Float::INFINITY
        end

        it 'should transfer -Float::INFINITY' do
          result = page.evaluate_function 'a => a', -Float::INFINITY
          expect(result).to eq(-Float::INFINITY)
        end

        #it('should transfer arrays', async({page, server}) => {
        #  const result = await page.evaluate(a => a, [1, 2, 3]);
        #  expect(result).toEqual([1,2,3]);
        #});
        it 'should transfer arrays as arrays, not objects' do
          result = page.evaluate_function 'a => Array.isArray(a)', [1, 2, 3]
          expect(result).to eq true
        end

        it 'should modify global environment' do
          page.evaluate_function '() => window.globalVar = 123'
          expect(page.evaluate('globalVar')).to eq 123
        end

        it 'should evaluate in the page context' do
          page.goto server.domain + 'global-var.html'
          expect(page.evaluate('globalVar')).to eq 123
        end

        # TODO
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
      end

      it 'evaluates javascript' do
        result = page.evaluate '7 * 3'
        expect(result).to eq 21
      end
    end

    describe '#frames' do
      it 'returns all frames in the page' do
        page.goto server.domain + "frames/nested-frames.html"
        expected_frames = [
          "http://localhost:4567/frames/nested-frames.html",
          "http://localhost:4567/frames/two-frames.html",
          "http://localhost:4567/frames/frame.html",
          "http://localhost:4567/frames/frame.html",
          "http://localhost:4567/frames/frame.html"
        ]
        expect(page.frames.map(&:url)).to eq expected_frames
      end
    end

    describe '#url' do
      it 'returns the pages current url' do
        expect(page.url).to eq "about:blank"
        page.goto server.empty_page
        expect(page.url).to eq server.empty_page
      end
    end

    describe '#title' do
      it 'should return the page title' do
        page.goto server.domain + "/title.html"
        expect(page.title).to eq 'Woof-Woof'
      end
    end

    describe 'set_content' do
      let(:expected_output) { '<html><head></head><body><div>hello</div></body></html>' }

      it 'sets page content' do
        page.set_content('<div>hello</div>')
        result = page.content
        expect(result).to eq expected_output
      end

      it 'should work with doctype' do
        doctype = '<!DOCTYPE html>'
        page.set_content "#{doctype}<div>hello</div>"
        result = page.content
        expect(result).to eq "#{doctype}#{expected_output}"
      end

      it 'should work with HTML 4 doctype' do
        doctype = '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">'
        page.set_content "#{doctype}<div>hello</div>"
        result = page.content
        expect(result).to eq "#{doctype}#{expected_output}"
      end

      xit 'should respect timeout' do
        pending 'raise a better error in lifecyclewatcher'
        img_path = 'timeout-img.png'
        expect do
          page.set_content("<img src='#{server.domain + img_path}'></img>", timeout: 0.01)
        end.to raise_error Timeout::Error
      end

      # TODO
      #it_fails_ffox('should respect default navigation timeout', async({page, server}) => {
      #  page.setDefaultNavigationTimeout(1);
      #  const imgPath = '/img.png';
      #  // stall for image
      #  server.setRoute(imgPath, (req, res) => {});
      #  let error = null;
      #  await page.setContent(`<img src="${server.PREFIX + imgPath}"></img>`).catch(e => error = e);
      #  expect(error).toBeInstanceOf(puppeteer.errors.TimeoutError);
      #});
      #it_fails_ffox('should await resources to load', async({page, server}) => {
      #  const imgPath = '/img.png';
      #  let imgResponse = null;
      #  server.setRoute(imgPath, (req, res) => imgResponse = res);
      #  let loaded = false;
      #  const contentPromise = page.setContent(`<img src="${server.PREFIX + imgPath}"></img>`).then(() => loaded = true);
      #  await server.waitForRequest(imgPath);
      #  expect(loaded).toBe(false);
      #  imgResponse.end();
      #  await contentPromise;
      #});
      #it('should work fast enough', async({page, server}) => {
      #  for (let i = 0; i < 20; ++i)
      #    await page.setContent('<div>yo</div>');
      #});
      #it('should work with tricky content', async({page, server}) => {
      #  await page.setContent('<div>hello world</div>' + '\x7F');
      #  expect(await page.$eval('div', div => div.textContent)).toBe('hello world');
      #});
      #it('should work with accents', async({page, server}) => {
      #  await page.setContent('<div>aberración</div>');
      #  expect(await page.$eval('div', div => div.textContent)).toBe('aberración');
      #});
      #it('should work with emojis', async({page, server}) => {
      #  await page.setContent('<div>🐥</div>');
      #  expect(await page.$eval('div', div => div.textContent)).toBe('🐥');
      #});
      #it('should work with newline', async({page, server}) => {
      #  await page.setContent('<div>\n</div>');
      #  expect(await page.$eval('div', div => div.textContent)).toBe('\n');
      #});
    end
  end
end
