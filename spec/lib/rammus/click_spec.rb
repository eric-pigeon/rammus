module Rammus
  RSpec.describe 'Click', browser: true do
    before { @_context = browser.create_context }
    after { @_context.close }
    let(:context) { @_context }
    let!(:page) { context.new_page }

    it 'can click buttons' do
      page.goto(server.domain + 'input/button.html').wait!
      page.click 'button'
      expect(page.evaluate('result').value!).to eq 'Clicked'
    end

    it 'should click svg' do
      content = <<~SVG
        <svg height="100" width="100">
          <circle onclick="javascript:window.__CLICKED=42" cx="50" cy="50" r="40" stroke="black" stroke-width="3" fill="red" />
        </svg>
      SVG
      page
      page.set_content(content).wait!
      page.click 'circle'
      expect(page.evaluate('window.__CLICKED').value!).to eq 42
    end

    it 'should click the button if window.Node is removed' do
      page.goto(server.domain + 'input/button.html').wait!
      page.evaluate('delete window.Node').wait!
      page.click 'button'
      expect(page.evaluate('result').value!).to eq 'Clicked'
    end

    it 'should click on a span with an inline element inside' do
      content = <<~HTML
        <style>
        span::before {
          content: 'q';
        }
        </style>
        <span onclick='javascript:window.CLICKED=42'></span>
      HTML
      page.set_content(content).wait!
      page.click 'span'
      expect(page.evaluate('window.CLICKED').value!).to eq 42
    end

    it 'should click the button after navigation ' do
      page.goto(server.domain + 'input/button.html').wait!
      page.click 'button'
      page.goto(server.domain + 'input/button.html').wait!
      page.click 'button'
      expect(page.evaluate('result').value!).to eq 'Clicked'
    end

    it 'should click with disabled javascript' do
      page.set_javascript_enabled false
      page.goto(server.domain + 'wrappedlink.html').wait!
      Concurrent::Promises.zip(
        page.wait_for_navigation,
        Concurrent::Promises.future { page.click('a') }
      ).wait!
      expect(page.url).to eq server.domain + 'wrappedlink.html#clicked'
    end

    it 'should click when one of inline box children is outside of viewport' do
      content = <<~HTML
        <style>
        i {
          position: absolute;
          top: -1000px;
        }
        </style>
        <span onclick='javascript:window.CLICKED = 42;'><i>woof</i><b>doggo</b></span>
      HTML
      page.set_content(content).wait!
      page.click 'span'
      expect(page.evaluate('window.CLICKED').value!).to eq 42
    end

    it 'should select the text by triple clicking' do
      page.goto(server.domain + 'input/textarea.html').wait!
      page.focus 'textarea'
      text = "This is the text that we are going to try to select. Let's see how it goes."
      page.keyboard.type text
      page.click 'textarea'
      page.click 'textarea', click_count: 2
      page.click 'textarea', click_count: 3
      function = <<~JAVASCRIPT
      () => {
        const textarea = document.querySelector('textarea');
        return textarea.value.substring(textarea.selectionStart, textarea.selectionEnd);
      }
      JAVASCRIPT
      expect(page.evaluate_function(function).value!).to eq text
    end

    it 'should click offscreen buttons' do
      page.goto(server.domain + 'offscreenbuttons.html').wait!
      messages = []
      page.on :console, -> (msg) { messages << msg.text }
      11.times do |i|
        # We might've scrolled to click a button - reset to (0, 0).
        page.evaluate_function("() => window.scrollTo(0, 0)").wait!
        page.click("#btn#{i}")
      end
      expect(messages).to eq [
        'button #0 clicked',
        'button #1 clicked',
        'button #2 clicked',
        'button #3 clicked',
        'button #4 clicked',
        'button #5 clicked',
        'button #6 clicked',
        'button #7 clicked',
        'button #8 clicked',
        'button #9 clicked',
        'button #10 clicked'
      ]
    end

    it 'should click wrapped links' do
      page.goto(server.domain + 'wrappedlink.html').wait!
      page.click 'a'
      expect(page.evaluate('window.__clicked').value!).to eq true
    end

    it 'should click on checkbox input and toggle' do
      page.goto(server.domain + 'input/checkbox.html').wait!
      expect(page.evaluate('result.check').value!).to eq nil
      page.click 'input#agree'
      expect(page.evaluate('result.check').value!).to eq true
      expect(page.evaluate('result.events').value!).to eq [
        'mouseover',
        'mouseenter',
        'mousemove',
        'mousedown',
        'mouseup',
        'click',
        'input',
        'change',
      ]
      page.click 'input#agree'
      expect(page.evaluate('result.check').value!).to eq false
    end

    it 'should click on checkbox label and toggle' do
      page.goto(server.domain + 'input/checkbox.html').wait!
      expect(page.evaluate('result.check').value!).to eq nil
      page.click 'label[for="agree"]'
      expect(page.evaluate('result.check').value!).to eq true
      expect(page.evaluate('result.events').value!).to eq [
        'click',
        'input',
        'change',
      ]
      page.click 'label[for="agree"]'
      expect(page.evaluate('result.check').value!).to eq false
    end

    it 'should fail to click a missing button' do
      page.goto(server.domain + 'input/checkbox.html').wait!
      expect { page.click 'button.does-not-exist' }
        .to raise_error 'No node found for selector: button.does-not-exist'
    end

    # @see https://github.com/GoogleChrome/puppeteer/issues/161
    it 'should not hang with touch-enabled viewports' do
      page.set_viewport Rammus.devices['iPhone 6'][:viewport]
      page.mouse.down
      page.mouse.move(100, 10)
      page.mouse.up
    end

    it 'should scroll and click the button' do
      page.goto(server.domain + 'input/scrollable.html').wait!
      page.click '#button-5'
      expect(page.evaluate("document.querySelector('#button-5').textContent").value!).to eq 'clicked'
      page.click '#button-80'
      expect(page.evaluate("document.querySelector('#button-80').textContent").value!).to eq 'clicked'
    end

    it 'should double click the button' do
      page.goto(server.domain + 'input/button.html').wait!
      function = <<~JAVASCRIPT
      () => {
        window.double = false;
        const button = document.querySelector('button');
        button.addEventListener('dblclick', event => {
          window.double = true;
        });
      }
      JAVASCRIPT
      page.evaluate_function(function).wait!
      button = page.query_selector 'button'
      button.click click_count: 2
      expect(page.evaluate('double').value!).to eq true
      expect(page.evaluate('result').value!).to eq 'Clicked'
    end

    it 'should click a partially obscured button' do
      page.goto(server.domain + 'input/button.html').wait!
      function = <<~JAVASCRIPT
      () => {
        const button = document.querySelector('button');
        button.textContent = 'Some really long text that will go offscreen';
        button.style.position = 'absolute';
        button.style.left = '368px';
      }
      JAVASCRIPT
      page.evaluate_function(function).wait!
      page.click 'button'
      expect(page.evaluate('window.result').value!).to eq 'Clicked'
    end

    it 'should click a rotated button' do
      page.goto(server.domain + 'input/rotatedButton.html').wait!
      page.click 'button'
      expect(page.evaluate('window.result').value!).to eq 'Clicked'
    end

    it 'should fire contextmenu event on right click' do
      page.goto(server.domain + 'input/scrollable.html').wait!
      page.click '#button-8', button: 'right'
      expect(page.evaluate("document.querySelector('#button-8').textContent").value!).to eq 'context menu'
    end

    # @see https://github.com/GoogleChrome/puppeteer/issues/206
    it 'should click links which cause navigation' do
      page.set_content("<a href='#{server.domain}'>empty.html</a>").wait!
      # This should not hang.
      page.click 'a'
    end

    it 'should click the button inside an iframe' do
      page.goto(server.domain).wait!
      page.set_content('<div style="width:100px;height:100px">spacer</div>').wait!
      attach_frame(page, 'button-test', server.domain + 'input/button.html').wait!
      frame = page.frames[1]
      button = frame.query_selector 'button'
      button.click
      expect(frame.evaluate('window.result').value!).to eq 'Clicked'
    end

    # TODO
    # @see https://github.com/GoogleChrome/puppeteer/issues/4110
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

    it 'should click the button with device_scale_factor set' do
      page.set_viewport width: 400, height: 400, device_scale_factor: 5
      expect(page.evaluate('window.devicePixelRatio').value!).to eq 5
      page.set_content('<div style="width:100px;height:100px">spacer</div>').wait!
      attach_frame(page, 'button-test', server.domain + 'input/button.html').wait!
      frame = page.frames[1]
      button = frame.query_selector 'button'
      button.click
      expect(frame.evaluate('window.result').value!).to eq 'Clicked'
    end
  end
end
