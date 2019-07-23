module Rammus
  RSpec.describe Mouse, browser: true do
    include Promise::Await
    before { @_context = browser.create_context }
    after { @_context.close }
    let(:context) { @_context }
    let!(:page) { context.new_page }

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
      await page.evaluate_function javascript
      page.mouse.click 50, 60
      event = await page.evaluate_function '() => window.clickPromise'
      expect(event["type"]).to eq 'click'
      expect(event["detail"]).to eq 1
      expect(event["clientX"]).to eq 50
      expect(event["clientY"]).to eq 60
      expect(event["isTrusted"]).to eq true
      expect(event["button"]).to eq 0
    end

    it 'should resize the textarea' do
      await page.goto server.domain + 'input/textarea.html'
      textarea_dimensions = await page.evaluate_function dimensions
      x = textarea_dimensions["x"]
      y = textarea_dimensions["y"]
      width = textarea_dimensions["width"]
      height = textarea_dimensions["height"]
      mouse = page.mouse
      mouse.move (x + width - 4), (y + height - 4)
      mouse.down
      mouse.move (x + width + 100), (y + height + 100)
      mouse.up
      new_textarea_dimensions = await page.evaluate_function dimensions
      expect(new_textarea_dimensions["width"]).to eq width + 104
      expect(new_textarea_dimensions["height"]).to eq height + 104
    end

    it 'should select the text with mouse' do
      await page.goto server.domain + 'input/textarea.html'
      page.focus 'textarea'
      text = "This is the text that we are going to try to select. Let's see how it goes."
      page.keyboard.type text
      # Firefox needs an extra frame here after typing or it will fail to set the scrollTop
      await page.evaluate_function '() => new Promise(requestAnimationFrame)'
      await page.evaluate_function "() => document.querySelector('textarea').scrollTop = 0"
      textarea_dimensions = await page.evaluate_function dimensions
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
      expect(await page.evaluate_function function).to eq text
    end

    it 'should trigger hover state' do
      await page.goto server.domain + 'input/scrollable.html'

      page.hover '#button-6'
      expect(await page.evaluate "document.querySelector('button:hover').id").to eq 'button-6'
      page.hover '#button-2'
      expect(await page.evaluate "document.querySelector('button:hover').id").to eq 'button-2'
      page.hover '#button-91'
      expect(await page.evaluate "document.querySelector('button:hover').id").to eq 'button-91'
    end

    it 'should trigger hover state with removed window.Node' do
      await page.goto server.domain + 'input/scrollable.html'
      await page.evaluate 'delete window.Node'
      page.hover '#button-6'
      expect(await page.evaluate "document.querySelector('button:hover').id").to eq 'button-6'
    end

    it 'should set modifier keys on click' do
      await page.goto server.domain + 'input/scrollable.html'
      await page.evaluate "document.querySelector('#button-3').addEventListener('mousedown', e => window.lastEvent = e, true)"
      modifiers = { 'Shift' => 'shiftKey', 'Control' => 'ctrlKey', 'Alt' => 'altKey', 'Meta' => 'metaKey' }
      # In Firefox, the Meta modifier only exists on Mac
      # if (FFOX && os.platform() !== 'darwin')
      #   delete modifiers['Meta'];
      # end
      modifiers.each do |modifier, key|
        page.keyboard.down modifier
        page.click '#button-3'
        expect(await page.evaluate_function "mod => window.lastEvent[mod]", key).to eq true
        page.keyboard.up modifier
      end
      page.click '#button-3'
      modifiers.each do |modifier, key|
        expect(await page.evaluate_function "mod => window.lastEvent[mod]", key).to eq false
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
      await page.evaluate_function function
      page.mouse.move 200, 300, steps: 5
      expect(await page.evaluate 'result').to eq [
        [120, 140],
        [140, 180],
        [160, 220],
        [180, 260],
        [200, 300]
      ]
    end

    # @see https://crbug.com/929806
    it 'should work with mobile viewports and cross process navigations' do
      await page.goto server.empty_page
      page.set_viewport width: 360, height: 640, is_mobile: true
      await page.goto server.cross_process_domain + 'mobile.html'
      await page.evaluate_function("() => {
        document.addEventListener('click', event => {
          window.result = {x: event.clientX, y: event.clientY};
        });
      }")

      page.mouse.click 30, 40

      expect(await page.evaluate('result')).to eq "x" => 30, "y" => 40
    end
  end
end
