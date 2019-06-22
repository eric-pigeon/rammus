module Chromiebara
  RSpec.describe Keyboard, browser: true do
    include Promise::Await
    before { @_context = browser.create_context }
    after { @_context.close }
    let(:context) { @_context }
    let!(:page) { context.new_page }

      it 'should type into a text area' do
        await page.evaluate_function "() => {
          const textarea = document.createElement('textarea');
          document.body.appendChild(textarea);
          textarea.focus();
        }"
        text = 'Hello world. I am the text that was typed!'
        page.keyboard.type text
        expect(await page.evaluate_function '() => document.querySelector("textarea").value').to eq text
      end

      it 'should press the metaKey' do
        await page.evaluate_function"() => {
          window.keyPromise = new Promise(resolve => document.addEventListener('keydown', event => resolve(event.key)));
        }"
        page.keyboard.press 'Meta'
        # FOX && os.platform() !== 'darwin'
        expect(await page.evaluate('keyPromise')).to eq 'Meta'
      end

      it 'should move with the arrow keys' do
        page.goto server.domain + '/input/textarea.html'
        page.type 'textarea', 'Hello World!'
        expect(await page.evaluate_function "() => document.querySelector('textarea').value").to eq 'Hello World!'
        'World!'.length.times { page.keyboard.press 'ArrowLeft' }
        page.keyboard.type 'inserted '
        expect(await page.evaluate_function "() => document.querySelector('textarea').value").to eq 'Hello inserted World!'
        page.keyboard.down 'Shift'
        'inserted!'.length.times { page.keyboard.press 'ArrowLeft' }
        page.keyboard.up 'Shift'
        page.keyboard.press 'Backspace'
        expect(await page.evaluate_function "() => document.querySelector('textarea').value").to eq 'Hello World!'
      end

      it 'should send a character with ElementHandle.press' do
        page.goto server.domain + '/input/textarea.html'
        textarea = page.query_selector 'textarea'
        textarea.press 'a'
        expect(await page.evaluate "document.querySelector('textarea').value").to eq 'a'

        await page.evaluate "window.addEventListener('keydown', e => e.preventDefault(), true)"

        textarea.press 'b'
        expect(await page.evaluate "document.querySelector('textarea').value").to eq 'a'
      end

      it 'ElementHandle#press should support |text| option' do
        page.goto server.domain + 'input/textarea.html'
        textarea = page.query_selector 'textarea'
        textarea.press 'a', text: 'ё'
        expect(await page.evaluate_function "() => document.querySelector('textarea').value").to eq 'ё'
      end

      it 'should send a character with send_character' do
         page.goto server.domain + '/input/textarea.html'
         page.focus 'textarea'
         page.keyboard.send_character '嗨'

         expect(await page.evaluate "document.querySelector('textarea').value").to eq '嗨'
         await page.evaluate "window.addEventListener('keydown', e => e.preventDefault(), true)"
         page.keyboard.send_character 'a'
         expect(await page.evaluate "document.querySelector('textarea').value").to eq '嗨a'
      end

      it 'should report shift_key' do
        page.goto server.domain + '/input/keyboard.html'
        keyboard = page.keyboard
        code_for_key = { 'Shift' => 16, 'Alt' => 18, 'Control' => 17 }

        code_for_key.each do |modifier_key, code|
          keyboard.down modifier_key
          expect(await page.evaluate 'getResult()').to eq "Keydown: #{modifier_key} #{modifier_key}Left #{code} [#{modifier_key}]"
          keyboard.down '!'
          # # Shift+! will generate a keypress
          if  modifier_key == 'Shift'
            expect(await page.evaluate 'getResult()').to eq "Keydown: ! Digit1 49 [#{modifier_key}]\nKeypress: ! Digit1 33 33 [#{modifier_key}]"
          else
            expect(await page.evaluate 'getResult()').to eq "Keydown: ! Digit1 49 [#{modifier_key}]"
          end

          keyboard.up '!'
          expect(await page.evaluate 'getResult()').to eq "Keyup: ! Digit1 49 [#{modifier_key}]"
          keyboard.up modifier_key
          expect(await page.evaluate 'getResult()').to eq "Keyup: #{modifier_key} #{modifier_key}Left #{code} []"
        end
      end

      it 'should report multiple modifiers' do
        page.goto server.domain + '/input/keyboard.html'
        keyboard = page.keyboard
        keyboard.down 'Control'
        expect(await page.evaluate "getResult()").to eq 'Keydown: Control ControlLeft 17 [Control]'
        keyboard.down 'Alt'
        expect(await page.evaluate "getResult()").to eq 'Keydown: Alt AltLeft 18 [Alt Control]'
        keyboard.down ';'
        expect(await page.evaluate "getResult()").to eq 'Keydown: ; Semicolon 186 [Alt Control]'
        keyboard.up ';'
        expect(await page.evaluate "getResult()").to eq 'Keyup: ; Semicolon 186 [Alt Control]'
        keyboard.up 'Control'
        expect(await page.evaluate "getResult()").to eq 'Keyup: Control ControlLeft 17 [Alt]'
        keyboard.up 'Alt'
        expect(await page.evaluate "getResult()").to eq 'Keyup: Alt AltLeft 18 []'
      end

      it 'should send proper codes while typing' do
        page.goto server.domain + '/input/keyboard.html'
        page.keyboard.type '!'
        expect(await page.evaluate "getResult()").to eq [
          'Keydown: ! Digit1 49 []',
          'Keypress: ! Digit1 33 33 []',
          'Keyup: ! Digit1 49 []'
        ].join("\n")
        page.keyboard.type '^'
        expect(await page.evaluate "getResult()").to eq [
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
        expect(await page.evaluate "getResult()").to eq [
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
        await page.evaluate_function(
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
        expect(await page.evaluate 'textarea.value').to eq 'He Wrd!'
      end

      it 'should specify repeat property' do
        page.goto server.domain + '/input/textarea.html'
        page.focus 'textarea'
        await page.evaluate("document.querySelector('textarea').addEventListener('keydown', e => window.lastEvent = e, true)")
        page.keyboard.down 'a'
        expect(await page.evaluate 'window.lastEvent.repeat').to eq false
        page.keyboard.press 'a'
        expect(await page.evaluate 'window.lastEvent.repeat').to eq true

        page.keyboard.down 'b'
        expect(await page.evaluate 'window.lastEvent.repeat').to eq false
        page.keyboard.down 'b'
        expect(await page.evaluate 'window.lastEvent.repeat').to eq true

        page.keyboard.up'a'
        page.keyboard.down'a'
        expect(await page.evaluate 'window.lastEvent.repeat').to eq false
      end

      it 'should type all kinds of characters' do
        page.goto server.domain + '/input/textarea.html'
        page.focus 'textarea'
        text = "This text goes onto two lines.\nThis character is 嗨.";
        page.keyboard.type text
        expect(await page.evaluate('result')).to eq text
      end

      it 'should specify location' do
        page.goto server.domain + '/input/textarea.html'
        await page.evaluate "window.addEventListener('keydown', event => window.keyLocation = event.location, true);"

        textarea = page.query_selector 'textarea'

        textarea.press 'Digit5'
        expect(await page.evaluate 'keyLocation').to eq 0

        textarea.press 'ControlLeft'
        expect(await page.evaluate 'keyLocation').to eq 1

        textarea.press 'ControlRight'
        expect(await page.evaluate 'keyLocation').to eq 2

        textarea.press 'NumpadSubtract'
        expect(await page.evaluate 'keyLocation').to eq 3
      end

      it 'should throw on unknown keys' do
        expect { page.keyboard.press('NotARealKey') }.to raise_error RuntimeError, "Unknown key: 'NotARealKey'"

        expect { page.keyboard.press('ё') }.to raise_error RuntimeError, "Unknown key: 'ё'"

        expect { page.keyboard.press('😊') }.to raise_error RuntimeError, "Unknown key: '😊'"
      end

      it'should type emoji' do
        page.goto server.domain + '/input/textarea.html'
        page.type 'textarea', '👹 Tokyo street Japan 🇯🇵'
        expect(await page.query_selector_evaluate_function 'textarea', 'textarea => textarea.value').to eq '👹 Tokyo street Japan 🇯🇵'
      end

      it 'should type emoji into an iframe' do
        page.goto server.empty_page
        attach_frame page, 'emoji-test', server.domain + 'input/textarea.html'
        frame = page.frames[1]
        textarea = frame.query_selector 'textarea'
        textarea.type '👹 Tokyo street Japan 🇯🇵'
        expect(await frame.query_selector_evaluate_function 'textarea', 'textarea => textarea.value').to eq '👹 Tokyo street Japan 🇯🇵'
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
        await page.evaluate_function function
        page.keyboard.press 'Meta'
        key, code, meta_key = await page.evaluate 'result'
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
end
