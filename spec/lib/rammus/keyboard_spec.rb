module Rammus
  RSpec.describe Keyboard, browser: true do
    before { @_context = browser.create_context }
    after { @_context.close }
    let(:context) { @_context }
    let!(:page) { context.new_page }

      it 'should type into a text area' do
        page.evaluate_function("() => {
          const textarea = document.createElement('textarea');
          document.body.appendChild(textarea);
          textarea.focus();
        }").wait!
        text = 'Hello world. I am the text that was typed!'
        page.keyboard.type text
        expect(page.evaluate_function('() => document.querySelector("textarea").value').value!).to eq text
      end

      it 'should press the metaKey' do
        page.evaluate_function("() => {
          window.keyPromise = new Promise(resolve => document.addEventListener('keydown', event => resolve(event.key)));
        }").wait!
        page.keyboard.press 'Meta'
        # FOX && os.platform() !== 'darwin'
        expect(page.evaluate('keyPromise').value!).to eq 'Meta'
      end

      it 'should move with the arrow keys' do
        page.goto(server.domain + '/input/textarea.html').wait!
        page.type 'textarea', 'Hello World!'
        expect(page.evaluate_function("() => document.querySelector('textarea').value").value!).to eq 'Hello World!'
        'World!'.length.times { page.keyboard.press 'ArrowLeft' }
        page.keyboard.type 'inserted '
        expect(page.evaluate_function("() => document.querySelector('textarea').value").value!).to eq 'Hello inserted World!'
        page.keyboard.down 'Shift'
        'inserted!'.length.times { page.keyboard.press 'ArrowLeft' }
        page.keyboard.up 'Shift'
        page.keyboard.press 'Backspace'
        expect(page.evaluate_function("() => document.querySelector('textarea').value").value!).to eq 'Hello World!'
      end

      it 'should send a character with ElementHandle.press' do
        page.goto(server.domain + '/input/textarea.html').wait!
        textarea = page.query_selector 'textarea'
        textarea.press 'a'
        expect(page.evaluate("document.querySelector('textarea').value").value!).to eq 'a'

        page.evaluate("window.addEventListener('keydown', e => e.preventDefault(), true)").wait!

        textarea.press 'b'
        expect(page.evaluate("document.querySelector('textarea').value").value!).to eq 'a'
      end

      it 'ElementHandle#press should support |text| option' do
        page.goto(server.domain + 'input/textarea.html').wait!
        textarea = page.query_selector 'textarea'
        textarea.press 'a', text: 'ё'
        expect(page.evaluate_function("() => document.querySelector('textarea').value").value!).to eq 'ё'
      end

      it 'should send a character with send_character' do
        page.goto(server.domain + '/input/textarea.html').wait!
         page.focus 'textarea'
         page.keyboard.send_character '嗨'

         expect(page.evaluate("document.querySelector('textarea').value").value!).to eq '嗨'
         page.evaluate("window.addEventListener('keydown', e => e.preventDefault(), true)").wait!
         page.keyboard.send_character 'a'
         expect(page.evaluate("document.querySelector('textarea').value").value!).to eq '嗨a'
      end

      it 'should report shift_key' do
        page.goto(server.domain + '/input/keyboard.html').wait!
        keyboard = page.keyboard
        code_for_key = { 'Shift' => 16, 'Alt' => 18, 'Control' => 17 }

        code_for_key.each do |modifier_key, code|
          keyboard.down modifier_key
          expect(page.evaluate('getResult()').value!).to eq "Keydown: #{modifier_key} #{modifier_key}Left #{code} [#{modifier_key}]"
          keyboard.down '!'
          # # Shift+! will generate a keypress
          if  modifier_key == 'Shift'
            expect(page.evaluate('getResult()').value!).to eq "Keydown: ! Digit1 49 [#{modifier_key}]\nKeypress: ! Digit1 33 33 [#{modifier_key}]"
          else
            expect( page.evaluate('getResult()').value!).to eq "Keydown: ! Digit1 49 [#{modifier_key}]"
          end

          keyboard.up '!'
          expect(page.evaluate('getResult()').value!).to eq "Keyup: ! Digit1 49 [#{modifier_key}]"
          keyboard.up modifier_key
          expect(page.evaluate('getResult()').value!).to eq "Keyup: #{modifier_key} #{modifier_key}Left #{code} []"
        end
      end

      it 'should report multiple modifiers' do
        page.goto(server.domain + '/input/keyboard.html').wait!
        keyboard = page.keyboard
        keyboard.down 'Control'
        expect(page.evaluate("getResult()").value!).to eq 'Keydown: Control ControlLeft 17 [Control]'
        keyboard.down 'Alt'
        expect(page.evaluate("getResult()").value!).to eq 'Keydown: Alt AltLeft 18 [Alt Control]'
        keyboard.down ';'
        expect(page.evaluate("getResult()").value!).to eq 'Keydown: ; Semicolon 186 [Alt Control]'
        keyboard.up ';'
        expect(page.evaluate("getResult()").value!).to eq 'Keyup: ; Semicolon 186 [Alt Control]'
        keyboard.up 'Control'
        expect(page.evaluate("getResult()").value!).to eq 'Keyup: Control ControlLeft 17 [Alt]'
        keyboard.up 'Alt'
        expect(page.evaluate("getResult()").value!).to eq 'Keyup: Alt AltLeft 18 []'
      end

      it 'should send proper codes while typing' do
        page.goto(server.domain + '/input/keyboard.html').wait!
        page.keyboard.type '!'
        expect(page.evaluate("getResult()").value!).to eq [
          'Keydown: ! Digit1 49 []',
          'Keypress: ! Digit1 33 33 []',
          'Keyup: ! Digit1 49 []'
        ].join("\n")
        page.keyboard.type '^'
        expect(page.evaluate("getResult()").value!).to eq [
          'Keydown: ^ Digit6 54 []',
          'Keypress: ^ Digit6 94 94 []',
           'Keyup: ^ Digit6 54 []'
        ].join("\n")
      end

      it 'should send proper codes while typing with shift' do
        page.goto(server.domain + '/input/keyboard.html').wait!
        keyboard = page.keyboard
        keyboard.down 'Shift'
        page.keyboard.type '~'
        expect(page.evaluate("getResult()").value!).to eq [
          'Keydown: Shift ShiftLeft 16 [Shift]',
          'Keydown: ~ Backquote 192 [Shift]', #// 192 is ` keyCode
          'Keypress: ~ Backquote 126 126 [Shift]', #// 126 is ~ charCode
          'Keyup: ~ Backquote 192 [Shift]'
        ].join("\n")
        keyboard.up 'Shift'
      end

      it 'should not type canceled events' do
        page.goto(server.domain + '/input/textarea.html').wait!
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
        ).wait!
        page.keyboard.type 'Hello World!'
        expect(page.evaluate('textarea.value').value!).to eq 'He Wrd!'
      end

      it 'should specify repeat property' do
        page.goto(server.domain + '/input/textarea.html').wait!
        page.focus 'textarea'
        page.evaluate("document.querySelector('textarea').addEventListener('keydown', e => window.lastEvent = e, true)").wait!
        page.keyboard.down 'a'
        expect(page.evaluate('window.lastEvent.repeat').value!).to eq false
        page.keyboard.press 'a'
        expect(page.evaluate('window.lastEvent.repeat').value!).to eq true

        page.keyboard.down 'b'
        expect(page.evaluate('window.lastEvent.repeat').value!).to eq false
        page.keyboard.down 'b'
        expect(page.evaluate('window.lastEvent.repeat').value!).to eq true

        page.keyboard.up'a'
        page.keyboard.down'a'
        expect(page.evaluate('window.lastEvent.repeat').value!).to eq false
      end

      it 'should type all kinds of characters' do
        page.goto(server.domain + '/input/textarea.html').wait!
        page.focus 'textarea'
        text = "This text goes onto two lines.\nThis character is 嗨.";
        page.keyboard.type text
        expect(page.evaluate('result').value!).to eq text
      end

      it 'should specify location' do
        page.goto(server.domain + '/input/textarea.html').wait!
        page.evaluate("window.addEventListener('keydown', event => window.keyLocation = event.location, true);").wait!

        textarea = page.query_selector 'textarea'

        textarea.press 'Digit5'
        expect(page.evaluate('keyLocation').value!).to eq 0

        textarea.press 'ControlLeft'
        expect(page.evaluate('keyLocation').value!).to eq 1

        textarea.press 'ControlRight'
        expect(page.evaluate('keyLocation').value!).to eq 2

        textarea.press 'NumpadSubtract'
        expect(page.evaluate('keyLocation').value!).to eq 3
      end

      it 'should throw on unknown keys' do
        expect { page.keyboard.press('NotARealKey') }.to raise_error RuntimeError, "Unknown key: 'NotARealKey'"

        expect { page.keyboard.press('ё') }.to raise_error RuntimeError, "Unknown key: 'ё'"

        expect { page.keyboard.press('😊') }.to raise_error RuntimeError, "Unknown key: '😊'"
      end

      it'should type emoji' do
        page.goto(server.domain + '/input/textarea.html').wait!
        page.type 'textarea', '👹 Tokyo street Japan 🇯🇵'
        expect(page.query_selector_evaluate_function('textarea', 'textarea => textarea.value').value!).to eq '👹 Tokyo street Japan 🇯🇵'
      end

      it 'should type emoji into an iframe' do
        page.goto(server.empty_page).wait!
        attach_frame(page, 'emoji-test', server.domain + 'input/textarea.html').wait!
        frame = page.frames[1]
        textarea = frame.query_selector 'textarea'
        textarea.type '👹 Tokyo street Japan 🇯🇵'
        expect(frame.query_selector_evaluate_function('textarea', 'textarea => textarea.value').value!).to eq '👹 Tokyo street Japan 🇯🇵'
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
        page.evaluate_function(function).wait!
        page.keyboard.press 'Meta'
        key, code, meta_key = page.evaluate('result').value!
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
