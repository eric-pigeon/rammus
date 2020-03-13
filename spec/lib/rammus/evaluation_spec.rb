module Rammus
  RSpec.describe 'Evaluation', browser: true do
    before { @_context = browser.create_context }
    after { @_context.close }
    let(:context) { @_context }
    let!(:page) { context.new_page }

    describe 'Page#evaluate_function' do
      it 'should work' do
        result = page.evaluate_function('() => 7 * 3').value!
        expect(result).to eq 21
      end

      it 'should transfer NAN' do
        result = page.evaluate_function("a => a", Float::NAN).value!
        expect(result).to be_a Float
        expect(result).to be_nan
      end

      it 'should transfer -0' do
        result = page.evaluate_function('a => a', -0).value!
        expect(result).to eq(-0)
      end

      it 'should transfer Float::INFINITY' do
        result = page.evaluate_function("a => a", Float::INFINITY).value!
        expect(result).to eq Float::INFINITY
      end

      it 'should transfer -Float::INFINITY' do
        result = page.evaluate_function("a => a", -Float::INFINITY).value!
        expect(result).to eq(-Float::INFINITY)
      end

      it 'should transfer arrays' do
        result = page.evaluate_function("a => a", [1, 2, 3]).value!
        expect(result).to eq [1,2,3]
      end

      it 'should transfer arrays as arrays, not objects' do
        result = page.evaluate_function("a => Array.isArray(a)", [1, 2, 3]).value!
        expect(result).to eq true
      end

      it 'should modify global environment' do
        page.evaluate_function("() => window.globalVar = 123").wait!
        expect(page.evaluate('globalVar').value!).to eq 123
      end

      it 'should evaluate in the page context' do
        page.goto(server.domain + 'global-var.html').wait!
        expect(page.evaluate('globalVar').value!).to eq 123
      end

      it 'should return undefined for objects with symbols' do
        expect(page.evaluate_function("() => [Symbol('foo4')]").value!).to eq nil
      end

      it 'should work with unicode chars' do
        result = page.evaluate_function("a => a['中文字符']", { '中文字符' => 42 }).value!
        expect(result).to eq 42
      end

      it 'should throw when evaluation triggers reload' do
        expect do
          page.evaluate_function("() => {
            location.reload();
            return new Promise(() => {});
          }").wait!
        end.to raise_error(/Protocol error/)
      end

      it 'should await promise' do
        result = page.evaluate_function("() => Promise.resolve(8 * 7)").value!
        expect(result).to eq 56
      end

      xit 'should work right after framenavigated' do
        frame_evaluation = nil
        page.on :frame_navigated, -> (frame) do
          # need to make this async otherwise #evaluate_function will block the event loop waiting
          # for the execution context to be created from
          await Promise.resolve(nil).then { frame_evaluation = frame.evaluate_function "() => 6 * 7" }
        end
        await page.goto server.empty_page
        expect(await frame_evaluation).to eq 42
      end

      it 'should work from-inside an exposed function' do
        # Setup inpage callback, which calls Page.evaluate
        page.expose_function 'callController' do |a, b|
          page.evaluate_function("(a, b) => a * b", a, b).wait!
        end
        result = page.evaluate_function("async function() {
          return await callController(9, 3);
        }").value!
        expect(result).to eq 27
      end

      it 'should reject promise with exception' do
        expect do
          page.evaluate_function("() => not.existing.object.property").value!
        end.to raise_error(/not is not defined/)
      end

      it 'should support thrown strings as error messages' do
        expect { page.evaluate_function("() => { throw 'qwerty'; }").value! }
          .to raise_error(/qwerty/)
      end

      it 'should support thrown numbers as error messages' do
        expect { page.evaluate_function("() => { throw 100500 }").value! }
          .to raise_error(/100500/)
      end

      it 'should return complex objects' do
        object = { "foo" => 'bar!' }
        result = page.evaluate_function("a => a", object).value!
        expect(result).to eq(object)
      end

      it 'should return BigInt' do
        result = page.evaluate_function("() => BigInt(42)").value!
        expect(result).to eq 42
      end

      it 'should return NaN' do
        result = page.evaluate_function("() => NaN").value!
        expect(result).to be_nan
      end

      it 'should return -0' do
        result = page.evaluate_function("() => -0").value!
        expect(result).to eq 0
      end

      it 'should return Infinity' do
        result = page.evaluate_function("() => Infinity").value!
        expect(result).to eq Float::INFINITY
      end

      it 'should return -Infinity' do
        result = page.evaluate_function("() => -Infinity").value!
        expect(result).to eq(-Float::INFINITY)
      end

      it 'should properly serialize null fields' do
        expect(page.evaluate_function("() => ({a: undefined})").value!).to eq({})
      end

      it 'should return nil for non-serializable objects' do
        expect(page.evaluate_function("() => window").value!).to eq nil
      end

      it 'should fail for circular object' do
        result = page.evaluate_function("() => {
          a = {};
          b = {a};
          a.b = b;
          return a;
        }").value!
        expect(result).to eq nil
      end

      it 'should be able to throw a tricky error' do
        window_handle = page.evaluate_handle_function("() => window").value!
        error_text =
          begin
            window_handle.json_value
          rescue => err
            err.message
          end
        error = page.evaluate_function("errorText => {
          throw new Error(errorText);
        }", error_text).rescue { |e| e }.value!
        expect(error.message).to include error_text
      end

      it 'should accept a string' do
        result = page.evaluate('1 + 2').value!
        expect(result).to eq 3
      end

      it 'should accept a string with semi colons' do
        result = page.evaluate('1 + 5;').value!
        expect(result).to eq 6
      end

      it 'should accept a string with comments' do
        result = page.evaluate("2 + 5;\n// do some math!").value!
        expect(result).to eq 7
      end

      it 'should accept element handle as an argument' do
        page.set_content('<section>42</section>').wait!
        element = page.query_selector 'section'
        text = page.evaluate_function("e => e.textContent", element).value!
        expect(text).to eq '42'
      end

      it 'should throw if underlying element was disposed' do
        page.set_content('<section>39</section>').wait!
        element = page.query_selector 'section'
        expect(element).not_to be_nil
        element.dispose

        expect do
          page.evaluate_function("e => e.textContent", element).value!
        end.to raise_error(/JSHandle is disposed/)
      end

      it 'should throw if element_handles are from other frames' do
        attach_frame(page, 'frame1', server.empty_page).wait!
        body_handle = page.frames[1].query_selector 'body'
        expect do
          page.evaluate_function("body => body.innerHTML", body_handle).value!
        end.to raise_error(/JSHandles can be evaluated only in the context they were created/)
      end

      it 'should simulate a user gesture' do
        result = page.evaluate_function("() => document.execCommand('copy')").value!
        expect(result).to eq true
      end

      it 'should throw a nice error after a navigation' do
        execution_context = page.main_frame.execution_context

        Concurrent::Promises.zip(
          page.wait_for_navigation,
          execution_context.evaluate_function("() => window.location.reload()")
        ).wait!
        expect { execution_context.evaluate_function("() => null").value! }
          .to raise_error(/navigation/)
      end

      it 'should not throw an error when evaluation does a navigation' do
        page.goto(server.domain + 'one-style.html').wait!
        result = page.evaluate_function("() => {
          window.location = '/empty.html';
          return [42];
        }").value!
        expect(result).to eq [42]
      end
    end

    describe 'Page#evaluate_on_new_document' do
      it 'should evaluate before anything else on the page' do
        page.evaluate_on_new_document "function(){ window.injected = 123; }"
        page.goto(server.domain + 'tamperable.html').wait!
        expect(page.evaluate_function("() => window.result").value!).to eq 123
      end

      it 'should work with CSP' do
        server.set_content_security_policy '/empty.html', 'script-src ' + server.domain
        page.evaluate_on_new_document "function() { window.injected = 123; }"
        page.goto(server.domain + 'empty.html').wait!
        expect(page.evaluate_function("() => window.injected").value!).to eq 123

        # Make sure CSP works.
        begin
          page.add_script_tag(content: 'window.e = 10;')
        rescue => _err
        end
        expect(page.evaluate_function('() => window.e').value!).to be nil
      end
    end

    describe 'Frame#evaluate_function' do
      it 'should have different execution contexts' do
        page.goto(server.empty_page).wait!
        attach_frame(page, 'frame1', server.empty_page).wait!
        expect(page.frames.length).to eq 2
        page.frames[0].evaluate_function("() => window.FOO = 'foo'").wait!
        page.frames[1].evaluate_function("() => window.FOO = 'bar'").wait!
        expect(page.frames[0].evaluate_function("() => window.FOO").value!).to eq 'foo'
        expect(page.frames[1].evaluate_function("() => window.FOO").value!).to eq 'bar'
      end

      it 'should have correct execution contexts' do
        page.goto(server.domain + 'frames/one-frame.html').wait!
        expect(page.frames.length).to eq 2
        expect(page.frames[0].evaluate_function('() => document.body.textContent.trim()').value!).to eq ''
        expect(page.frames[1].evaluate_function('() => document.body.textContent.trim()').value!).to eq "Hi, I'm frame"
      end

      it 'should execute after cross-site navigation' do
        page.goto(server.empty_page).wait!
        main_frame = page.main_frame
        expect(main_frame.evaluate_function('() => window.location.href').value!).to include 'localhost'
        page.goto(server.cross_process_domain + 'empty.html').wait!
        expect(main_frame.evaluate_function('() => window.location.href').value!).to include '127'
      end
    end
  end
end
