# frozen_string_literal: true

module Rammus
  RSpec.describe Mouse, browser: true do
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
      page.evaluate_function(javascript).wait!
      page.mouse.click 50, 60
      event = page.evaluate_function('() => window.clickPromise').value!
      expect(event["type"]).to eq 'click'
      expect(event["detail"]).to eq 1
      expect(event["clientX"]).to eq 50
      expect(event["clientY"]).to eq 60
      expect(event["isTrusted"]).to eq true
      expect(event["button"]).to eq 0
    end

    it 'should resize the textarea' do
      page.goto(server.domain + 'input/textarea.html').wait!
      textarea_dimensions = page.evaluate_function(dimensions).value!
      x = textarea_dimensions["x"]
      y = textarea_dimensions["y"]
      width = textarea_dimensions["width"]
      height = textarea_dimensions["height"]
      mouse = page.mouse
      mouse.move (x + width - 4), (y + height - 4)
      mouse.down
      mouse.move (x + width + 100), (y + height + 100)
      mouse.up
      new_textarea_dimensions = page.evaluate_function(dimensions).value!
      expect(new_textarea_dimensions["width"]).to eq width + 104
      expect(new_textarea_dimensions["height"]).to eq height + 104
    end

    it 'should select the text with mouse' do
      page.goto(server.domain + 'input/textarea.html').wait!
      page.focus 'textarea'
      text = "This is the text that we are going to try to select. Let's see how it goes."
      page.keyboard.type text
      # Firefox needs an extra frame here after typing or it will fail to set the scrollTop
      page.evaluate_function('() => new Promise(requestAnimationFrame)').wait!
      page.evaluate_function("() => document.querySelector('textarea').scrollTop = 0").wait!
      textarea_dimensions = page.evaluate_function(dimensions).value!
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
      expect(page.evaluate_function(function).value!).to eq text
    end

    it 'should trigger hover state' do
      page.goto(server.domain + 'input/scrollable.html').wait!

      page.hover '#button-6'
      expect(page.evaluate("document.querySelector('button:hover').id").value!).to eq 'button-6'
      page.hover '#button-2'
      expect(page.evaluate("document.querySelector('button:hover').id").value!).to eq 'button-2'
      page.hover '#button-91'
      expect(page.evaluate("document.querySelector('button:hover').id").value!).to eq 'button-91'
    end

    it 'should trigger hover state with removed window.Node' do
      page.goto(server.domain + 'input/scrollable.html').wait!
      page.evaluate('delete window.Node').wait!
      page.hover '#button-6'
      expect(page.evaluate("document.querySelector('button:hover').id").value!)
        .to eq 'button-6'
    end

    it 'should set modifier keys on click' do
      page.goto(server.domain + 'input/scrollable.html').wait!
      page.evaluate("document.querySelector('#button-3').addEventListener('mousedown', e => window.lastEvent = e, true)").wait!
      modifiers = { 'Shift' => 'shiftKey', 'Control' => 'ctrlKey', 'Alt' => 'altKey', 'Meta' => 'metaKey' }
      # In Firefox, the Meta modifier only exists on Mac
      # if (FFOX && os.platform() !== 'darwin')
      #   delete modifiers['Meta'];
      # end
      modifiers.each do |modifier, key|
        page.keyboard.down modifier
        page.click '#button-3'
        expect(page.evaluate_function("mod => window.lastEvent[mod]", key).value!).to eq true
        page.keyboard.up modifier
      end
      page.click '#button-3'
      modifiers.each do |_modifier, key|
        expect(page.evaluate_function("mod => window.lastEvent[mod]", key).value!).to eq false
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
      page.evaluate_function(function).wait!
      page.mouse.move 200, 300, steps: 5
      expect(page.evaluate('result').value!).to eq [
        [120, 140],
        [140, 180],
        [160, 220],
        [180, 260],
        [200, 300]
      ]
    end

    # @see https://crbug.com/929806
    it 'should work with mobile viewports and cross process navigations' do
      page.goto(server.empty_page).wait!
      page.set_viewport width: 360, height: 640, is_mobile: true
      page.goto(server.cross_process_domain + 'mobile.html').wait!
      page.evaluate_function("() => {
        document.addEventListener('click', event => {
          window.result = {x: event.clientX, y: event.clientY};
        });
      }").wait!

      page.mouse.click 30, 40

      expect(page.evaluate('result').value!).to eq "x" => 30, "y" => 40
    end
  end
end
