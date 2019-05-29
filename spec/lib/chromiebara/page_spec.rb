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

    context 'cookies' do
      describe '#cookies' do
        it 'should return empty array without cookies' do
          page.goto server.empty_page
          expect(page.cookies).to eq []
        end

        it 'should get a cookie' do
          page.goto(server.empty_page)
          page.evaluate("document.cookie = 'username=John Doe';")
          expect(page.cookies).to eq([
            {
              "name" => 'username',
              "value" => 'John Doe',
              "domain" => 'localhost',
              "path" => '/',
              "expires" => -1,
              "size" => 16,
              "httpOnly" => false,
              "secure" => false,
              "session" => true
            }
          ])
        end

        it 'should report httpOnly' do
          page.goto server.domain + 'http-cookie'
          cookie = page.cookies.first
          expect(cookie['httpOnly']).to eq true
        end

        it 'should get multiple cookies' do
          page.goto server.empty_page

          page.evaluate("document.cookie = 'username=John Doe'; document.cookie = 'password=1234';")
          cookies = page.cookies.sort { |a, b| a["name"] <=> b["name"] }
          expect(cookies).to eq([
            {
              "name" => 'password',
              "value" => '1234',
              "domain" => 'localhost',
              "path" => '/',
              "expires" => -1,
              "size" => 12,
              "httpOnly" => false,
              "secure" => false,
              "session" => true
            },
            {
              "name" => 'username',
              "value" => 'John Doe',
              "domain" => 'localhost',
              "path" => '/',
              "expires" => -1,
              "size" => 16,
              "httpOnly" => false,
              "secure" => false,
              "session" => true
            }
          ])
        end

        it 'should get cookies from multiple urls' do
          page.set_cookie(
            { url: 'https://foo.com', name: 'doggo', value: 'woofs' },
            { url: 'https://bar.com', name: 'catto', value: 'purrs' },
            { url: 'https://baz.com', name: 'birdo', value: 'tweets' }
          )
          cookies = page.cookies('https://foo.com', 'https://baz.com')
          cookies.sort { |a, b| a["name"] <=> b["name"] }
          expect(cookies).to eq([
            {
              "name" => 'birdo',
              "value" => 'tweets',
              "domain" => 'baz.com',
              "path" => '/',
              "expires" => -1,
              "size" => 11,
              "httpOnly" => false,
              "secure" => true,
              "session" => true
            },
            {
              "name" => 'doggo',
              "value" => 'woofs',
              "domain" => 'foo.com',
              "path" => '/',
              "expires" => -1,
              "size" => 10,
              "httpOnly" => false,
              "secure" => true,
              "session" => true
            }
          ])
        end
      end

      describe '#set_cookie' do
        it 'sets cookies' do
          page.goto server.empty_page

          page.set_cookie name: 'password', value: '123456'
          expect(page.evaluate 'document.cookie').to eq 'password=123456'
        end

        it 'should isolate cookies in browser contexts' do
          context_2 = browser.create_context
          page_2 = context_2.new_page

          page.goto server.empty_page
          page_2.goto server.empty_page

          page.set_cookie name: 'page1cookie', value: 'page1value'
          page_2.set_cookie name: 'page2cookie', value: 'page2value'

          cookies_1 = page.cookies
          cookies_2 = page_2.cookies
          expect(cookies_1.length).to eq 1
          expect(cookies_2.length).to eq 1

          expect(cookies_1[0]["name"]).to eq 'page1cookie'
          expect(cookies_1[0]["value"]).to eq 'page1value'

          expect(cookies_2[0]["name"]).to eq 'page2cookie'
          expect(cookies_2[0]["value"]).to eq 'page2value'

          context_2.close
        end

        it 'should set multiple cookies' do
          page.goto server.empty_page
          page.set_cookie(
            { name: 'password', value: '123456' },
            { name: 'foo', value: 'bar' }
          )
          cookies = page.evaluate "document.cookie.split(';').map(cookie => cookie.trim()).sort();"
          expect(cookies).to eq ["foo=bar", "password=123456"]
        end

        it 'should have expires set to -1 for session cookies' do
          page.goto server.empty_page
          page.set_cookie name: 'password', value: '123456'
          cookie = page.cookies.first
          expect(cookie["session"]).to eq true
          expect(cookie["expires"]).to eq(-1)
        end

        it 'should set cookie with reasonable defaults' do
          page.goto server.empty_page
          page.set_cookie name: 'password', value: '123456'
          expect(page.cookies).to eq [
            "name" => 'password',
            "value" => '123456',
            "domain" => 'localhost',
            "path" => '/',
            "expires" => -1,
            "size" => 14,
            "httpOnly" => false,
            "secure" => false,
            "session" => true
          ]
        end

        it 'should set a cookie with a path' do
          page.goto server.domain + 'grid.html'
          page.set_cookie(name: 'gridcookie', value: 'GRID', path: '/grid.html')
          expect(page.cookies).to eq([
            "name" => 'gridcookie',
            "value" => 'GRID',
            "domain" => 'localhost',
            "path" => '/grid.html',
            "expires" => -1,
            "size" => 14,
            "httpOnly" => false,
            "secure" => false,
            "session" => true
          ])
          expect(page.evaluate('document.cookie')).to eq 'gridcookie=GRID'
          page.goto server.empty_page
          expect(page.cookies()).to eq []
          expect(page.evaluate 'document.cookie').to eq ''
          page.goto server.domain + 'grid.html'
          expect(page.evaluate 'document.cookie').to eq 'gridcookie=GRID'
        end

        it 'should not set a cookie on a blank page' do
           page.goto 'about:blank'

           expect {page.set_cookie({ name: 'example-cookie', value: 'best' }) }
             .to raise_error ProtocolError, /At least one of the url and domain needs to be specified/
        end

        it 'should not set a cookie with blank page URL' do
          page.goto server.empty_page
          expect do
            page.set_cookie(
              { name: 'example-cookie', value: 'best' },
              { url: 'about:blank', name: 'example-cookie-blank', value: 'best' }
            )
          end.to raise_error RuntimeError, /Blank page can not have cookie "example-cookie-blank"/
        end

        it 'should not set a cookie on a data URL page' do
          page.goto 'data:,Hello%2C%20World!'

          expect { page.set_cookie name: 'example-cookie', value: 'best' }
            .to raise_error(ProtocolError, /At least one of the url and domain needs to be specified/)
        end

        it 'should default to setting secure cookie for HTTPS websites' do
          page.goto server.empty_page
          secure_url = 'https://example.com'
          page.set_cookie url: secure_url, name: 'foo', value: 'bar'
          cookie, * = page.cookies secure_url
          expect(cookie["secure"]).to eq true
        end

        it 'should be able to set unsecure cookie for HTTP website' do
          page.goto server.empty_page
          http_url = 'http://example.com'
          page.set_cookie url: http_url, name: 'foo', value: 'bar'
          cookie, * = page.cookies http_url
          expect(cookie["secure"]).to eq false
        end

        it 'should set a cookie on a different domain' do
          page.goto server.empty_page
          page.set_cookie url: 'https://www.example.com', name: 'example-cookie', value: 'best'
          expect(page.evaluate 'document.cookie').to eq ''
          expect(page.cookies).to eq []
          expect(page.cookies 'https://www.example.com').to eq [{
            "name" => 'example-cookie',
            "value" => 'best',
            "domain" => 'www.example.com',
            "path" => '/',
            "expires" => -1,
            "size" => 18,
            "httpOnly" => false,
            "secure" => true,
            "session" => true
          }]
        end

        xit 'should set cookies from a frame' do
          page.goto server.domain + "/grid.html"
          page.set_cookie name: 'localhost-cookie', value: 'best'
          _function = <<~JAVASCRIPT
            src => {
               let fulfill;
               const promise = new Promise(x => fulfill = x);
               const iframe = document.createElement('iframe');
               document.body.appendChild(iframe);
               iframe.onload = fulfill;
               iframe.src = src;
               return promise;
            }
          JAVASCRIPT
          # await page.evaluate(src => {
          #   let fulfill;
          #   const promise = new Promise(x => fulfill = x);
          #   const iframe = document.createElement('iframe');
          #   document.body.appendChild(iframe);
          #   iframe.onload = fulfill;
          #   iframe.src = src;
          #   return promise;
          # }, server.CROSS_PROCESS_PREFIX);
          # await page.setCookie({name: '127-cookie', value: 'worst', url: server.CROSS_PROCESS_PREFIX});
          # expect(await page.evaluate('document.cookie')).toBe('localhost-cookie=best');
          # expect(await page.frames()[1].evaluate('document.cookie')).toBe('127-cookie=worst');
          #
          # expect(await page.cookies()).toEqual([{
          #   name: 'localhost-cookie',
          #   value: 'best',
          #   domain: 'localhost',
          #   path: '/',
          #   expires: -1,
          #   size: 20,
          #   httpOnly: false,
          #   secure: false,
          #   session: true
          # }]);
          #
          # expect(await page.cookies(server.CROSS_PROCESS_PREFIX)).toEqual([{
          #   name: '127-cookie',
          #   value: 'worst',
          #   domain: '127.0.0.1',
          #   path: '/',
          #   expires: -1,
          #   size: 15,
          #   httpOnly: false,
          #   secure: false,
          #   session: true
          # }]);
        end
      end

      describe '#delete_cookies' do
        it 'deletes cookies' do
          page.goto server.empty_page
          page.set_cookie(
            { name: 'cookie1', value: '1' },
            { name: 'cookie2', value: '2' },
            { name: 'cookie3', value: '3' }
          )
          expect(page.evaluate 'document.cookie').to eq 'cookie1=1; cookie2=2; cookie3=3'
          page.delete_cookie(name: 'cookie2')
          expect(page.evaluate 'document.cookie').to eq 'cookie1=1; cookie3=3'
        end
      end
    end

    describe '#click' do
      it 'can click buttons' do
        page.goto server.domain + 'input/button.html'
        page.click 'button'
        expect(page.evaluate 'result').to eq 'Clicked'
      end

      #it('should click svg', async({page, server}) => {
      #  await page.setContent(`
      #    <svg height="100" width="100">
      #      <circle onclick="javascript:window.__CLICKED=42" cx="50" cy="50" r="40" stroke="black" stroke-width="3" fill="red" />
      #    </svg>
      #  `);
      #  await page.click('circle');
      #  expect(await page.evaluate(() => window.__CLICKED)).toBe(42);
      #});
      #it_fails_ffox('should click the button if window.Node is removed', async({page, server}) => {
      #  await page.goto(server.PREFIX + '/input/button.html');
      #  await page.evaluate(() => delete window.Node);
      #  await page.click('button');
      #  expect(await page.evaluate(() => result)).toBe('Clicked');
      #});
      #// @see https://github.com/GoogleChrome/puppeteer/issues/4281
      #it('should click on a span with an inline element inside', async({page, server}) => {
      #  await page.setContent(`
      #    <style>
      #    span::before {
      #      content: 'q';
      #    }
      #    </style>
      #    <span onclick='javascript:window.CLICKED=42'></span>
      #  `);
      #  await page.click('span');
      #  expect(await page.evaluate(() => window.CLICKED)).toBe(42);
      #});
      #it('should click the button after navigation ', async({page, server}) => {
      #  await page.goto(server.PREFIX + '/input/button.html');
      #  await page.click('button');
      #  await page.goto(server.PREFIX + '/input/button.html');
      #  await page.click('button');
      #  expect(await page.evaluate(() => result)).toBe('Clicked');
      #});
      #it_fails_ffox('should click with disabled javascript', async({page, server}) => {
      #  await page.setJavaScriptEnabled(false);
      #  await page.goto(server.PREFIX + '/wrappedlink.html');
      #  await Promise.all([
      #    page.click('a'),
      #    page.waitForNavigation()
      #  ]);
      #  expect(page.url()).toBe(server.PREFIX + '/wrappedlink.html#clicked');
      #});
      #it_fails_ffox('should click when one of inline box children is outside of viewport', async({page, server}) => {
      #  await page.setContent(`
      #    <style>
      #    i {
      #      position: absolute;
      #      top: -1000px;
      #    }
      #    </style>
      #    <span onclick='javascript:window.CLICKED = 42;'><i>woof</i><b>doggo</b></span>
      #  `);
      #  await page.click('span');
      #  expect(await page.evaluate(() => window.CLICKED)).toBe(42);
      #});
      #it('should select the text by triple clicking', async({page, server}) => {
      #  await page.goto(server.PREFIX + '/input/textarea.html');
      #  await page.focus('textarea');
      #  const text = 'This is the text that we are going to try to select. Let\'s see how it goes.';
      #  await page.keyboard.type(text);
      #  await page.click('textarea');
      #  await page.click('textarea', {clickCount: 2});
      #  await page.click('textarea', {clickCount: 3});
      #  expect(await page.evaluate(() => {
      #    const textarea = document.querySelector('textarea');
      #    return textarea.value.substring(textarea.selectionStart, textarea.selectionEnd);
      #  })).toBe(text);
      #});
      #it('should click offscreen buttons', async({page, server}) => {
      #  await page.goto(server.PREFIX + '/offscreenbuttons.html');
      #  const messages = [];
      #  page.on('console', msg => messages.push(msg.text()));
      #  for (let i = 0; i < 11; ++i) {
      #    // We might've scrolled to click a button - reset to (0, 0).
      #    await page.evaluate(() => window.scrollTo(0, 0));
      #    await page.click(`#btn${i}`);
      #  }
      #  expect(messages).toEqual([
      #    'button #0 clicked',
      #    'button #1 clicked',
      #    'button #2 clicked',
      #    'button #3 clicked',
      #    'button #4 clicked',
      #    'button #5 clicked',
      #    'button #6 clicked',
      #    'button #7 clicked',
      #    'button #8 clicked',
      #    'button #9 clicked',
      #    'button #10 clicked'
      #  ]);
      #});

      #it('should click wrapped links', async({page, server}) => {
      #  await page.goto(server.PREFIX + '/wrappedlink.html');
      #  await page.click('a');
      #  expect(await page.evaluate(() => window.__clicked)).toBe(true);
      #});

      #it('should click on checkbox input and toggle', async({page, server}) => {
      #  await page.goto(server.PREFIX + '/input/checkbox.html');
      #  expect(await page.evaluate(() => result.check)).toBe(null);
      #  await page.click('input#agree');
      #  expect(await page.evaluate(() => result.check)).toBe(true);
      #  expect(await page.evaluate(() => result.events)).toEqual([
      #    'mouseover',
      #    'mouseenter',
      #    'mousemove',
      #    'mousedown',
      #    'mouseup',
      #    'click',
      #    'input',
      #    'change',
      #  ]);
      #  await page.click('input#agree');
      #  expect(await page.evaluate(() => result.check)).toBe(false);
      #});

      #it('should click on checkbox label and toggle', async({page, server}) => {
      #  await page.goto(server.PREFIX + '/input/checkbox.html');
      #  expect(await page.evaluate(() => result.check)).toBe(null);
      #  await page.click('label[for="agree"]');
      #  expect(await page.evaluate(() => result.check)).toBe(true);
      #  expect(await page.evaluate(() => result.events)).toEqual([
      #    'click',
      #    'input',
      #    'change',
      #  ]);
      #  await page.click('label[for="agree"]');
      #  expect(await page.evaluate(() => result.check)).toBe(false);
      #});

      #it('should fail to click a missing button', async({page, server}) => {
      #  await page.goto(server.PREFIX + '/input/button.html');
      #  let error = null;
      #  await page.click('button.does-not-exist').catch(e => error = e);
      #  expect(error.message).toBe('No node found for selector: button.does-not-exist');
      #});
      #// @see https://github.com/GoogleChrome/puppeteer/issues/161
      #it('should not hang with touch-enabled viewports', async({page, server}) => {
      #  await page.setViewport(puppeteer.devices['iPhone 6'].viewport);
      #  await page.mouse.down();
      #  await page.mouse.move(100, 10);
      #  await page.mouse.up();
      #});
      #it('should scroll and click the button', async({page, server}) => {
      #  await page.goto(server.PREFIX + '/input/scrollable.html');
      #  await page.click('#button-5');
      #  expect(await page.evaluate(() => document.querySelector('#button-5').textContent)).toBe('clicked');
      #  await page.click('#button-80');
      #  expect(await page.evaluate(() => document.querySelector('#button-80').textContent)).toBe('clicked');
      #});
      #it('should double click the button', async({page, server}) => {
      #  await page.goto(server.PREFIX + '/input/button.html');
      #  await page.evaluate(() => {
      #    window.double = false;
      #    const button = document.querySelector('button');
      #    button.addEventListener('dblclick', event => {
      #      window.double = true;
      #    });
      #  });
      #  const button = await page.$('button');
      #  await button.click({ clickCount: 2 });
      #  expect(await page.evaluate('double')).toBe(true);
      #  expect(await page.evaluate('result')).toBe('Clicked');
      #});
      #it('should click a partially obscured button', async({page, server}) => {
      #  await page.goto(server.PREFIX + '/input/button.html');
      #  await page.evaluate(() => {
      #    const button = document.querySelector('button');
      #    button.textContent = 'Some really long text that will go offscreen';
      #    button.style.position = 'absolute';
      #    button.style.left = '368px';
      #  });
      #  await page.click('button');
      #  expect(await page.evaluate(() => window.result)).toBe('Clicked');
      #});
      #it('should click a rotated button', async({page, server}) => {
      #  await page.goto(server.PREFIX + '/input/rotatedButton.html');
      #  await page.click('button');
      #  expect(await page.evaluate(() => result)).toBe('Clicked');
      #});
      #it('should fire contextmenu event on right click', async({page, server}) => {
      #  await page.goto(server.PREFIX + '/input/scrollable.html');
      #  await page.click('#button-8', {button: 'right'});
      #  expect(await page.evaluate(() => document.querySelector('#button-8').textContent)).toBe('context menu');
      #});
      #// @see https://github.com/GoogleChrome/puppeteer/issues/206
      #it('should click links which cause navigation', async({page, server}) => {
      #  await page.setContent(`<a href="${server.EMPTY_PAGE}">empty.html</a>`);
      #  // This await should not hang.
      #  await page.click('a');
      #});
      #it('should click the button inside an iframe', async({page, server}) => {
      #  await page.goto(server.EMPTY_PAGE);
      #  await page.setContent('<div style="width:100px;height:100px">spacer</div>');
      #  await utils.attachFrame(page, 'button-test', server.PREFIX + '/input/button.html');
      #  const frame = page.frames()[1];
      #  const button = await frame.$('button');
      #  await button.click();
      #  expect(await frame.evaluate(() => window.result)).toBe('Clicked');
      #});
      #// @see https://github.com/GoogleChrome/puppeteer/issues/4110
      #xit('should click the button with fixed position inside an iframe', async({page, server}) => {
      #  await page.goto(server.EMPTY_PAGE);
      #  await page.setViewport({width: 500, height: 500});
      #  await page.setContent('<div style="width:100px;height:2000px">spacer</div>');
      #  await utils.attachFrame(page, 'button-test', server.CROSS_PROCESS_PREFIX + '/input/button.html');
      #  const frame = page.frames()[1];
      #  await frame.$eval('button', button => button.style.setProperty('position', 'fixed'));
      #  await frame.click('button');
      #  expect(await frame.evaluate(() => window.result)).toBe('Clicked');
      #});
      #it('should click the button with deviceScaleFactor set', async({page, server}) => {
      #  await page.setViewport({width: 400, height: 400, deviceScaleFactor: 5});
      #  expect(await page.evaluate(() => window.devicePixelRatio)).toBe(5);
      #  await page.setContent('<div style="width:100px;height:100px">spacer</div>');
      #  await utils.attachFrame(page, 'button-test', server.PREFIX + '/input/button.html');
      #  const frame = page.frames()[1];
      #  const button = await frame.$('button');
      #  await button.click();
      #  expect(await frame.evaluate(() => window.result)).toBe('Clicked');
      #});
    end

    describe '#evaluate' do
      context 'passing javascript function' do
        it 'transfers NaN' do
          result = page.evaluate('a => a', 'NaN', function: true)
          expect(result).to eq 'NaN'
        end

        it 'transfers -0' do
          result = page.evaluate('a => a', -0, function: true);
          expect(result).to eq 0
        end

        it 'should transfer Float::INFINITY' do
          result = page.evaluate('a => a', Float::INFINITY, function: true);
          expect(result).to eq Float::INFINITY
        end

        it 'should transfer -Float::INFINITY' do
          result = page.evaluate('a => a', -Float::INFINITY, function: true);
          expect(result).to eq(-Float::INFINITY)
        end

        #it('should transfer arrays', async({page, server}) => {
        #  const result = await page.evaluate(a => a, [1, 2, 3]);
        #  expect(result).toEqual([1,2,3]);
        #});
        it 'should transfer arrays as arrays, not objects' do
          result = page.evaluate('a => Array.isArray(a)', [1, 2, 3], function: true)
          expect(result).to eq true
        end;

        it 'should modify global environment' do
          page.evaluate('() => window.globalVar = 123', function: true)
          expect(page.evaluate('globalVar')).to eq 123
        end

        it 'should evaluate in the page context' do
          page.goto server.domain + 'global-var.html'
          expect(page.evaluate('globalVar')).to eq 123
        end

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

    describe '#keyboard' do
      it 'should type into a text area' do
        page.evaluate_function "() => {
          const textarea = document.createElement('textarea');
          document.body.appendChild(textarea);
          textarea.focus();
        }"
        text = 'Hello world. I am the text that was typed!'
        page.keyboard.type text
        expect(page.evaluate_function '() => document.querySelector("textarea").value').to eq text
      end

      it 'should press the metaKey' do
        page.evaluate_function"() => {
          window.keyPromise = new Promise(resolve => document.addEventListener('keydown', event => resolve(event.key)));
        }"
        page.keyboard.press 'Meta'
        # FOX && os.platform() !== 'darwin'
        expect(page.evaluate('keyPromise')).to eq 'Meta'
      end

      it 'should move with the arrow keys' do
        page.goto server.domain + '/input/textarea.html'
        page.type 'textarea', 'Hello World!'
        expect(page.evaluate_function "() => document.querySelector('textarea').value").to eq 'Hello World!'
        'World!'.length.times { page.keyboard.press 'ArrowLeft' }
        page.keyboard.type 'inserted '
        expect(page.evaluate_function "() => document.querySelector('textarea').value").to eq 'Hello inserted World!'
        page.keyboard.down 'Shift'
        'inserted!'.length.times { page.keyboard.press 'ArrowLeft' }
        page.keyboard.up 'Shift'
        page.keyboard.press 'Backspace'
        expect(page.evaluate_function "() => document.querySelector('textarea').value").to eq 'Hello World!'
      end

      it 'should send a character with ElementHandle.press' do
        page.goto server.domain + '/input/textarea.html'
        textarea = page.query_selector 'textarea'
        textarea.press 'a'
        expect(page.evaluate "document.querySelector('textarea').value").to eq 'a'

        page.evaluate "window.addEventListener('keydown', e => e.preventDefault(), true)"

        textarea.press 'b'
        expect(page.evaluate "document.querySelector('textarea').value").to eq 'a'
      end

      #it_fails_ffox('ElementHandle.press should support |text| option', async({page, server}) => {
      #  await page.goto(server.PREFIX + '/input/textarea.html');
      #  const textarea = await page.$('textarea');
      #  await textarea.press('a', {text: 'ё'});
      #  expect(await page.evaluate(() => document.querySelector('textarea').value)).toBe('ё');
      #});

      it 'should send a character with send_character' do
         page.goto server.domain + '/input/textarea.html'
         page.focus 'textarea'
         page.keyboard.send_character '嗨'

         expect(page.evaluate "document.querySelector('textarea').value").to eq '嗨'
         page.evaluate "window.addEventListener('keydown', e => e.preventDefault(), true)"
         page.keyboard.send_character 'a'
         expect(page.evaluate "document.querySelector('textarea').value").to eq '嗨a'
      end

      it 'should report shift_key' do
        page.goto server.domain + '/input/keyboard.html'
        keyboard = page.keyboard
        code_for_key = { 'Shift' => 16, 'Alt' => 18, 'Control' => 17 }

        code_for_key.each do |modifier_key, code|
          keyboard.down modifier_key
          expect(page.evaluate 'getResult()').to eq "Keydown: #{modifier_key} #{modifier_key}Left #{code} [#{modifier_key}]"
          keyboard.down '!'
          # # Shift+! will generate a keypress
          if  modifier_key == 'Shift'
            expect(page.evaluate 'getResult()').to eq "Keydown: ! Digit1 49 [#{modifier_key}]\nKeypress: ! Digit1 33 33 [#{modifier_key}]"
          else
            expect(page.evaluate 'getResult()').to eq "Keydown: ! Digit1 49 [#{modifier_key}]"
          end

          keyboard.up '!'
          expect(page.evaluate 'getResult()').to eq "Keyup: ! Digit1 49 [#{modifier_key}]"
          keyboard.up modifier_key
          expect(page.evaluate 'getResult()').to eq "Keyup: #{modifier_key} #{modifier_key}Left #{code} []"
        end
      end

      it 'should report multiple modifiers' do
        page.goto server.domain + '/input/keyboard.html'
        keyboard = page.keyboard
        keyboard.down 'Control'
        expect(page.evaluate "getResult()").to eq 'Keydown: Control ControlLeft 17 [Control]'
        keyboard.down 'Alt'
        expect(page.evaluate "getResult()").to eq 'Keydown: Alt AltLeft 18 [Alt Control]'
        keyboard.down ';'
        expect(page.evaluate "getResult()").to eq 'Keydown: ; Semicolon 186 [Alt Control]'
        keyboard.up ';'
        expect(page.evaluate "getResult()").to eq 'Keyup: ; Semicolon 186 [Alt Control]'
        keyboard.up 'Control'
        expect(page.evaluate "getResult()").to eq 'Keyup: Control ControlLeft 17 [Alt]'
        keyboard.up 'Alt'
        expect(page.evaluate "getResult()").to eq 'Keyup: Alt AltLeft 18 []'
      end

      it 'should send proper codes while typing' do
        page.goto server.domain + '/input/keyboard.html'
        page.keyboard.type '!'
        expect(page.evaluate "getResult()").to eq [
          'Keydown: ! Digit1 49 []',
          'Keypress: ! Digit1 33 33 []',
          'Keyup: ! Digit1 49 []'
        ].join("\n")
        page.keyboard.type '^'
        expect(page.evaluate "getResult()").to eq [
          'Keydown: ^ Digit6 54 []',
          'Keypress: ^ Digit6 94 94 []',
           'Keyup: ^ Digit6 54 []'
        ].join("\n")
      end

      it 'should send proper codes while typing with shift' do
        page.goto server.domain + '/input/keyboard.html'
        keyboard = page.keyboard
        keyboard.down 'Shift'
        page.keyboard.type '~'
        expect(page.evaluate "getResult()").to eq [
          'Keydown: Shift ShiftLeft 16 [Shift]',
          'Keydown: ~ Backquote 192 [Shift]', #// 192 is ` keyCode
          'Keypress: ~ Backquote 126 126 [Shift]', #// 126 is ~ charCode
          'Keyup: ~ Backquote 192 [Shift]'
        ].join("\n")
        keyboard.up 'Shift'
      end

      it 'should not type canceled events' do
        page.goto server.domain + '/input/textarea.html'
        page.focus 'textarea'
        page.evaluate_function(
          <<~JAVASCRIPT
          () => {
           window.addEventListener('keydown', event => {
             event.stopPropagation();
             event.stopImmediatePropagation();
             if (event.key === 'l')
               event.preventDefault();
             if (event.key === 'o')
               event.preventDefault();
           }, false);
         }
         JAVASCRIPT
        )
        page.keyboard.type 'Hello World!'
        expect(page.evaluate 'textarea.value').to eq 'He Wrd!'
      end

      it 'should specify repeat property' do
        page.goto server.domain + '/input/textarea.html'
        page.focus 'textarea'
        page.evaluate("document.querySelector('textarea').addEventListener('keydown', e => window.lastEvent = e, true)")
        page.keyboard.down 'a'
        expect(page.evaluate 'window.lastEvent.repeat').to eq false
        page.keyboard.press 'a'
        expect(page.evaluate 'window.lastEvent.repeat').to eq true

        page.keyboard.down 'b'
        expect(page.evaluate 'window.lastEvent.repeat').to eq false
        page.keyboard.down 'b'
        expect(page.evaluate 'window.lastEvent.repeat').to eq true

        page.keyboard.up'a'
        page.keyboard.down'a'
        expect(page.evaluate 'window.lastEvent.repeat').to eq false
      end

      it 'should type all kinds of characters' do
        page.goto server.domain + '/input/textarea.html'
        page.focus 'textarea'
        text = "This text goes onto two lines.\nThis character is 嗨.";
        page.keyboard.type text
        expect(page.evaluate('result')).to eq text
      end

      it 'should specify location' do
        page.goto server.domain + '/input/textarea.html'
        page.evaluate "window.addEventListener('keydown', event => window.keyLocation = event.location, true);"

        textarea = page.query_selector 'textarea'

        textarea.press 'Digit5'
        expect(page.evaluate 'keyLocation').to eq 0

        textarea.press 'ControlLeft'
        expect(page.evaluate 'keyLocation').to eq 1

        textarea.press 'ControlRight'
        expect(page.evaluate 'keyLocation').to eq 2

        textarea.press 'NumpadSubtract'
        expect(page.evaluate 'keyLocation').to eq 3
      end

      it 'should throw on unknown keys' do
        expect { page.keyboard.press('NotARealKey') }.to raise_error RuntimeError, "Unknown key: 'NotARealKey'"

        expect { page.keyboard.press('ё') }.to raise_error RuntimeError, "Unknown key: 'ё'"

        expect { page.keyboard.press('😊') }.to raise_error RuntimeError, "Unknown key: '😊'"
      end

      it'should type emoji' do
        page.goto server.domain + '/input/textarea.html'
        page.type 'textarea', '👹 Tokyo street Japan 🇯🇵'
        expect(page.query_selector_evaluate_function 'textarea', 'textarea => textarea.value').to eq '👹 Tokyo street Japan 🇯🇵'
      end

      it 'should type emoji into an iframe' do
        page.goto server.empty_page
        attach_frame page, 'emoji-test', server.domain + 'input/textarea.html'
        frame = page.frames[1]
        textarea = frame.query_selector 'textarea'
        textarea.type '👹 Tokyo street Japan 🇯🇵'
        expect(frame.query_selector_evaluate_function 'textarea', 'textarea => textarea.value').to eq '👹 Tokyo street Japan 🇯🇵'
      end

      it 'should press the meta key' do
        function = <<~JAVASCRIPT
        () => {
          window.result = null;
          document.addEventListener('keydown', event => {
            window.result = [event.key, event.code, event.metaKey];
          });
        }
        JAVASCRIPT
        page.evaluate_function function
        page.keyboard.press 'Meta'
        key, code, meta_key = page.evaluate 'result'
        # if (FFOX && os.platform() !== 'darwin')
        #   expect(key).toBe('OS');
        # else
           expect(key).to eq 'Meta'

        # if (FFOX)
        #   expect(code).toBe('OSLeft');
        # else
           expect(code).to eq 'MetaLeft'

        # if (FFOX && os.platform() !== 'darwin')
        #   expect(metaKey).toBe(false);
        # else
          expect(meta_key).to eq true
      end
    end

    describe '#mouse' do
      let(:dimensions) do
        <<~JAVASCRIPT
        () => {
          const rect = document.querySelector('textarea').getBoundingClientRect();
          return {
            x: rect.left,
            y: rect.top,
            width: rect.width,
            height: rect.height
          };
        }
        JAVASCRIPT
      end

      it 'should click the document' do
        javascript = <<~JAVASCRIPT
        () => {
          window.clickPromise = new Promise(resolve => {
            document.addEventListener('click', event => {
              resolve({
                type: event.type,
                detail: event.detail,
                clientX: event.clientX,
                clientY: event.clientY,
                isTrusted: event.isTrusted,
                button: event.button
              });
            });
          });
        }
        JAVASCRIPT
        page.evaluate javascript, function: true
        page.mouse.click 50, 60
        event = page.evaluate('() => window.clickPromise', function: true)
        expect(event["type"]).to eq 'click'
        expect(event["detail"]).to eq 1
        expect(event["clientX"]).to eq 50
        expect(event["clientY"]).to eq 60
        expect(event["isTrusted"]).to eq true
        expect(event["button"]).to eq 0
      end

      it 'should resize the textarea' do
        page.goto server.domain + 'input/textarea.html'
        textarea_dimensions = page.evaluate dimensions, function: true
        x = textarea_dimensions["x"]
        y = textarea_dimensions["y"]
        width = textarea_dimensions["width"]
        height = textarea_dimensions["height"]
        mouse = page.mouse
        mouse.move (x + width - 4), (y + height - 4)
        mouse.down
        mouse.move (x + width + 100), (y + height + 100)
        mouse.up
        new_textarea_dimensions = page.evaluate dimensions, function: true
        expect(new_textarea_dimensions["width"]).to eq width + 104
        expect(new_textarea_dimensions["height"]).to eq height + 104
      end

      it 'should select the text with mouse' do
        page.goto server.domain + 'input/textarea.html'
        page.focus 'textarea'
        text = "This is the text that we are going to try to select. Let's see how it goes."
        page.keyboard.type text
        # Firefox needs an extra frame here after typing or it will fail to set the scrollTop
        page.evaluate('() => new Promise(requestAnimationFrame)', function: true)
        page.evaluate("() => document.querySelector('textarea').scrollTop = 0", function: true)
        textarea_dimensions = page.evaluate dimensions, function: true
        page.mouse.move textarea_dimensions["x"] + 2, textarea_dimensions["y"] + 2
        page.mouse.down
        page.mouse.move 100, 100
        page.mouse.up
        function = <<~JAVASCRIPT
        () => {
          const textarea = document.querySelector('textarea');
          return textarea.value.substring(textarea.selectionStart, textarea.selectionEnd);
        }
        JAVASCRIPT
        expect(page.evaluate function, function: true).to eq text
      end

      it 'should trigger hover state' do
        page.goto server.domain + 'input/scrollable.html'

        page.hover '#button-6'
        expect(page.evaluate "document.querySelector('button:hover').id").to eq 'button-6'
        page.hover '#button-2'
        expect(page.evaluate "document.querySelector('button:hover').id").to eq 'button-2'
        page.hover '#button-91'
        expect(page.evaluate "document.querySelector('button:hover').id").to eq 'button-91'
      end

      it 'should trigger hover state with removed window.Node' do
        page.goto server.domain + 'input/scrollable.html'
        page.evaluate 'delete window.Node'
        page.hover '#button-6'
        expect(page.evaluate "document.querySelector('button:hover').id").to eq 'button-6'
      end

      it 'should set modifier keys on click' do
        page.goto server.domain + 'input/scrollable.html'
        page.evaluate "document.querySelector('#button-3').addEventListener('mousedown', e => window.lastEvent = e, true)"
        modifiers = { 'Shift' => 'shiftKey', 'Control' => 'ctrlKey', 'Alt' => 'altKey', 'Meta' => 'metaKey' }
        # In Firefox, the Meta modifier only exists on Mac
        # if (FFOX && os.platform() !== 'darwin')
        #   delete modifiers['Meta'];
        # end
        modifiers.each do |modifier, key|
          page.keyboard.down modifier
          page.click '#button-3'
          expect(page.evaluate_function "mod => window.lastEvent[mod]", key).to eq true
          page.keyboard.up modifier
        end
        page.click '#button-3'
        modifiers.each do |modifier, key|
          expect(page.evaluate_function "mod => window.lastEvent[mod]", key).to eq false
        end
      end

      it 'should tween mouse movement' do
        page.mouse.move 100, 100
        function = <<~JAVASCRIPT
        () => {
          window.result = [];
          document.addEventListener('mousemove', event => {
            window.result.push([event.clientX, event.clientY]);
          });
        }
        JAVASCRIPT
        page.evaluate_function function
        page.mouse.move 200, 300, steps: 5
        expect(page.evaluate 'result').to eq [
          [120, 140],
          [140, 180],
          [160, 220],
          [180, 260],
          [200, 300]
        ]
      end

      #// @see https://crbug.com/929806
      xit 'should work with mobile viewports and cross process navigations' do
        # TODO
        # page.goto server.empty_page
        # page.set_viewport width: 360, height: 640, isMobile: true
        # await page.goto(server.CROSS_PROCESS_PREFIX + '/mobile.html');
        # await page.evaluate(() => {
        #   document.addEventListener('click', event => {
        #     window.result = {x: event.clientX, y: event.clientY};
        #   });
        # });

        # await page.mouse.click(30, 40);

        # expect(await page.evaluate('result')).toEqual({x: 30, y: 40});
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

      it 'should respect timeout' do
        pending 'raise a better error in lifecyclewatcher'
        img_path = 'timeout-img.png'
        expect do
          page.set_content("<img src='#{server.domain + img_path}'></img>", timeout: 0.01)
        end.to raise_error Timeout::Error
      end

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

    context 'query selector' do
      #describe('Page.$eval', function() {
      #  it('should work', async({page, server}) => {
      #    await page.setContent('<section id="testAttribute">43543</section>');
      #    const idAttribute = await page.$eval('section', e => e.id);
      #    expect(idAttribute).toBe('testAttribute');
      #  });
      #  it('should accept arguments', async({page, server}) => {
      #    await page.setContent('<section>hello</section>');
      #    const text = await page.$eval('section', (e, suffix) => e.textContent + suffix, ' world!');
      #    expect(text).toBe('hello world!');
      #  });
      #  it('should accept ElementHandles as arguments', async({page, server}) => {
      #    await page.setContent('<section>hello</section><div> world</div>');
      #    const divHandle = await page.$('div');
      #    const text = await page.$eval('section', (e, div) => e.textContent + div.textContent, divHandle);
      #    expect(text).toBe('hello world');
      #  });
      #  it('should throw error if no element is found', async({page, server}) => {
      #    let error = null;
      #    await page.$eval('section', e => e.id).catch(e => error = e);
      #    expect(error.message).toContain('failed to find element matching selector "section"');
      #  });
      #});

      #describe('Page.$$eval', function() {
      #  it('should work', async({page, server}) => {
      #    await page.setContent('<div>hello</div><div>beautiful</div><div>world!</div>');
      #    const divsCount = await page.$$eval('div', divs => divs.length);
      #    expect(divsCount).toBe(3);
      #  });
      #});

      describe '#query_selector' do
        #it('should query existing element', async({page, server}) => {
        #  await page.setContent('<section>test</section>');
        #  const element = await page.$('section');
        #  expect(element).toBeTruthy();
        #});
        #it('should return null for non-existing element', async({page, server}) => {
        #  const element = await page.$('non-existing-element');
        #  expect(element).toBe(null);
        #});
      end

      #describe('Page.$$', function() {
      #  it('should query existing elements', async({page, server}) => {
      #    await page.setContent('<div>A</div><br/><div>B</div>');
      #    const elements = await page.$$('div');
      #    expect(elements.length).toBe(2);
      #    const promises = elements.map(element => page.evaluate(e => e.textContent, element));
      #    expect(await Promise.all(promises)).toEqual(['A', 'B']);
      #  });
      #  it('should return empty array if nothing is found', async({page, server}) => {
      #    await page.goto(server.EMPTY_PAGE);
      #    const elements = await page.$$('div');
      #    expect(elements.length).toBe(0);
      #  });
      #});

      #describe('Path.$x', function() {
      #  it('should query existing element', async({page, server}) => {
      #    await page.setContent('<section>test</section>');
      #    const elements = await page.$x('/html/body/section');
      #    expect(elements[0]).toBeTruthy();
      #    expect(elements.length).toBe(1);
      #  });
      #  it('should return empty array for non-existing element', async({page, server}) => {
      #    const element = await page.$x('/html/body/non-existing-element');
      #    expect(element).toEqual([]);
      #  });
      #  it('should return multiple elements', async({page, sever}) => {
      #    await page.setContent('<div></div><div></div>');
      #    const elements = await page.$x('/html/body/div');
      #    expect(elements.length).toBe(2);
      #  });
      #});

      #describe('ElementHandle.$', function() {
      #  it('should query existing element', async({page, server}) => {
      #    await page.goto(server.PREFIX + '/playground.html');
      #    await page.setContent('<html><body><div class="second"><div class="inner">A</div></div></body></html>');
      #    const html = await page.$('html');
      #    const second = await html.$('.second');
      #    const inner = await second.$('.inner');
      #    const content = await page.evaluate(e => e.textContent, inner);
      #    expect(content).toBe('A');
      #  });

      #  it('should return null for non-existing element', async({page, server}) => {
      #    await page.setContent('<html><body><div class="second"><div class="inner">B</div></div></body></html>');
      #    const html = await page.$('html');
      #    const second = await html.$('.third');
      #    expect(second).toBe(null);
      #  });
      #});
      #describe('ElementHandle.$eval', function() {
      #  it('should work', async({page, server}) => {
      #    await page.setContent('<html><body><div class="tweet"><div class="like">100</div><div class="retweets">10</div></div></body></html>');
      #    const tweet = await page.$('.tweet');
      #    const content = await tweet.$eval('.like', node => node.innerText);
      #    expect(content).toBe('100');
      #  });

      #  it('should retrieve content from subtree', async({page, server}) => {
      #    const htmlContent = '<div class="a">not-a-child-div</div><div id="myId"><div class="a">a-child-div</div></div>';
      #    await page.setContent(htmlContent);
      #    const elementHandle = await page.$('#myId');
      #    const content = await elementHandle.$eval('.a', node => node.innerText);
      #    expect(content).toBe('a-child-div');
      #  });

      #  it('should throw in case of missing selector', async({page, server}) => {
      #    const htmlContent = '<div class="a">not-a-child-div</div><div id="myId"></div>';
      #    await page.setContent(htmlContent);
      #    const elementHandle = await page.$('#myId');
      #    const errorMessage = await elementHandle.$eval('.a', node => node.innerText).catch(error => error.message);
      #    expect(errorMessage).toBe(`Error: failed to find element matching selector ".a"`);
      #  });
      #});
      #describe('ElementHandle.$$eval', function() {
      #  it('should work', async({page, server}) => {
      #    await page.setContent('<html><body><div class="tweet"><div class="like">100</div><div class="like">10</div></div></body></html>');
      #    const tweet = await page.$('.tweet');
      #    const content = await tweet.$$eval('.like', nodes => nodes.map(n => n.innerText));
      #    expect(content).toEqual(['100', '10']);
      #  });

      #  it('should retrieve content from subtree', async({page, server}) => {
      #    const htmlContent = '<div class="a">not-a-child-div</div><div id="myId"><div class="a">a1-child-div</div><div class="a">a2-child-div</div></div>';
      #    await page.setContent(htmlContent);
      #    const elementHandle = await page.$('#myId');
      #    const content = await elementHandle.$$eval('.a', nodes => nodes.map(n => n.innerText));
      #    expect(content).toEqual(['a1-child-div', 'a2-child-div']);
      #  });

      #  it('should not throw in case of missing selector', async({page, server}) => {
      #    const htmlContent = '<div class="a">not-a-child-div</div><div id="myId"></div>';
      #    await page.setContent(htmlContent);
      #    const elementHandle = await page.$('#myId');
      #    const nodesLength = await elementHandle.$$eval('.a', nodes => nodes.length);
      #    expect(nodesLength).toBe(0);
      #  });

      #});

      #describe('ElementHandle.$$', function() {
      #  it('should query existing elements', async({page, server}) => {
      #    await page.setContent('<html><body><div>A</div><br/><div>B</div></body></html>');
      #    const html = await page.$('html');
      #    const elements = await html.$$('div');
      #    expect(elements.length).toBe(2);
      #    const promises = elements.map(element => page.evaluate(e => e.textContent, element));
      #    expect(await Promise.all(promises)).toEqual(['A', 'B']);
      #  });

      #  it('should return empty array for non-existing elements', async({page, server}) => {
      #    await page.setContent('<html><body><span>A</span><br/><span>B</span></body></html>');
      #    const html = await page.$('html');
      #    const elements = await html.$$('div');
      #    expect(elements.length).toBe(0);
      #  });
      #});

      #describe('ElementHandle.$x', function() {
      #  it('should query existing element', async({page, server}) => {
      #    await page.goto(server.PREFIX + '/playground.html');
      #    await page.setContent('<html><body><div class="second"><div class="inner">A</div></div></body></html>');
      #    const html = await page.$('html');
      #    const second = await html.$x(`./body/div[contains(@class, 'second')]`);
      #    const inner = await second[0].$x(`./div[contains(@class, 'inner')]`);
      #    const content = await page.evaluate(e => e.textContent, inner[0]);
      #    expect(content).toBe('A');
      #  });

      #  it('should return null for non-existing element', async({page, server}) => {
      #    await page.setContent('<html><body><div class="second"><div class="inner">B</div></div></body></html>');
      #    const html = await page.$('html');
      #    const second = await html.$x(`/div[contains(@class, 'third')]`);
      #    expect(second).toEqual([]);
      #  });
      #});
    end
  end
end
