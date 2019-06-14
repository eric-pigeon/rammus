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

      # TODO
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
        page.evaluate_function javascript
        page.mouse.click 50, 60
        event = page.evaluate_function '() => window.clickPromise'
        expect(event["type"]).to eq 'click'
        expect(event["detail"]).to eq 1
        expect(event["clientX"]).to eq 50
        expect(event["clientY"]).to eq 60
        expect(event["isTrusted"]).to eq true
        expect(event["button"]).to eq 0
      end

      it 'should resize the textarea' do
        page.goto server.domain + 'input/textarea.html'
        textarea_dimensions = page.evaluate_function dimensions
        x = textarea_dimensions["x"]
        y = textarea_dimensions["y"]
        width = textarea_dimensions["width"]
        height = textarea_dimensions["height"]
        mouse = page.mouse
        mouse.move (x + width - 4), (y + height - 4)
        mouse.down
        mouse.move (x + width + 100), (y + height + 100)
        mouse.up
        new_textarea_dimensions = page.evaluate_function dimensions
        expect(new_textarea_dimensions["width"]).to eq width + 104
        expect(new_textarea_dimensions["height"]).to eq height + 104
      end

      it 'should select the text with mouse' do
        page.goto server.domain + 'input/textarea.html'
        page.focus 'textarea'
        text = "This is the text that we are going to try to select. Let's see how it goes."
        page.keyboard.type text
        # Firefox needs an extra frame here after typing or it will fail to set the scrollTop
        page.evaluate_function '() => new Promise(requestAnimationFrame)'
        page.evaluate_function "() => document.querySelector('textarea').scrollTop = 0"
        textarea_dimensions = page.evaluate_function dimensions
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
        expect(page.evaluate_function function).to eq text
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

      # TODO
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
