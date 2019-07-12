module Chromiebara
  RSpec.describe 'Click', browser: true do
    include Promise::Await
    before { @_context = browser.create_context }
    after { @_context.close }
    let(:context) { @_context }
    let!(:page) { context.new_page }

    it 'can click buttons' do
      await page.goto server.domain + 'input/button.html'
      page.click 'button'
      expect(await page.evaluate 'result').to eq 'Clicked'
    end

    it 'should click svg' do
      content = <<~SVG
        <svg height="100" width="100">
          <circle onclick="javascript:window.__CLICKED=42" cx="50" cy="50" r="40" stroke="black" stroke-width="3" fill="red" />
        </svg>
      SVG
      page
      await page.set_content content
      page.click 'circle'
      expect(await page.evaluate 'window.__CLICKED').to eq 42
    end

    it 'should click the button if window.Node is removed' do
      await page.goto server.domain + 'input/button.html'
      await page.evaluate 'delete window.Node'
      page.click 'button'
      expect(await page.evaluate 'result').to eq 'Clicked'
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
      await page.set_content content
      page.click 'span'
      expect(await page.evaluate 'window.CLICKED').to eq 42
    end

    it 'should click the button after navigation ' do
      await page.goto server.domain + 'input/button.html'
      page.click 'button'
      await page.goto server.domain + 'input/button.html'
      page.click 'button'
      expect(await page.evaluate 'result').to eq 'Clicked'
    end

    it 'should click with disabled javascript' do
      page.set_javascript_enabled false
      await page.goto server.domain + 'wrappedlink.html'
      await Promise.all(
        page.wait_for_navigation,
        page.click('a')
      )
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
      await page.set_content content
      page.click 'span'
      expect(await page.evaluate 'window.CLICKED').to eq 42
    end

    it 'should select the text by triple clicking' do
      await page.goto server.domain + 'input/textarea.html'
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
      expect(await page.evaluate_function function).to eq text
    end

    it 'should click offscreen buttons' do
      await page.goto server.domain + 'offscreenbuttons.html'
      messages = []
      page.on :console, -> (msg) { messages << msg.text }
      11.times do |i|
        # We might've scrolled to click a button - reset to (0, 0).
        await page.evaluate_function "() => window.scrollTo(0, 0)"
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
      await page.goto server.domain + 'wrappedlink.html'
      page.click 'a'
      expect(await page.evaluate 'window.__clicked').to eq true
    end

    it 'should click on checkbox input and toggle' do
      await page.goto server.domain + 'input/checkbox.html'
      expect(await page.evaluate 'result.check').to eq nil
      page.click 'input#agree'
      expect(await page.evaluate 'result.check').to eq true
      expect(await page.evaluate 'result.events').to eq [
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
      expect(await page.evaluate 'result.check').to eq false
    end

    it 'should click on checkbox label and toggle' do
      await page.goto server.domain + 'input/checkbox.html'
      expect(await page.evaluate 'result.check').to eq nil
      page.click 'label[for="agree"]'
      expect(await page.evaluate 'result.check').to eq true
      expect(await page.evaluate 'result.events').to eq [
        'click',
        'input',
        'change',
      ]
      page.click 'label[for="agree"]'
      expect(await page.evaluate 'result.check').to eq false
    end

    it 'should fail to click a missing button' do
      await page.goto server.domain + 'input/checkbox.html'
      expect { page.click 'button.does-not-exist' }
        .to raise_error 'No node found for selector: button.does-not-exist'
    end

    # @see https://github.com/GoogleChrome/puppeteer/issues/161
    it 'should not hang with touch-enabled viewports' do
      page.set_viewport Chromiebara.devices['iPhone 6'][:viewport]
      page.mouse.down
      page.mouse.move(100, 10)
      page.mouse.up
    end

    it 'should scroll and click the button' do
      await page.goto server.domain + 'input/scrollable.html'
      page.click '#button-5'
      expect(await page.evaluate "document.querySelector('#button-5').textContent").to eq 'clicked'
      page.click '#button-80'
      expect(await page.evaluate "document.querySelector('#button-80').textContent").to eq 'clicked'
    end

    it 'should double click the button' do
      await page.goto server.domain + 'input/button.html'
      function = <<~JAVASCRIPT
      () => {
        window.double = false;
        const button = document.querySelector('button');
        button.addEventListener('dblclick', event => {
          window.double = true;
        });
      }
      JAVASCRIPT
      await page.evaluate_function function
      button = page.query_selector 'button'
      button.click click_count: 2
      expect(await page.evaluate 'double').to eq true
      expect(await page.evaluate 'result').to eq 'Clicked'
    end

    it 'should click a partially obscured button' do
      await page.goto server.domain + 'input/button.html'
      function = <<~JAVASCRIPT
      () => {
        const button = document.querySelector('button');
        button.textContent = 'Some really long text that will go offscreen';
        button.style.position = 'absolute';
        button.style.left = '368px';
      }
      JAVASCRIPT
      await page.evaluate_function function
      page.click 'button'
      expect(await page.evaluate 'window.result').to eq 'Clicked'
    end

    it 'should click a rotated button' do
      await page.goto server.domain + 'input/rotatedButton.html'
      page.click 'button'
      expect(await page.evaluate 'window.result').to eq 'Clicked'
    end

    it 'should fire contextmenu event on right click' do
      await page.goto server.domain + 'input/scrollable.html'
      page.click '#button-8', button: 'right'
      expect(await page.evaluate "document.querySelector('#button-8').textContent").to eq 'context menu'
    end

    # @see https://github.com/GoogleChrome/puppeteer/issues/206
    it 'should click links which cause navigation' do
      await page.set_content("<a href='#{server.domain}'>empty.html</a>");
      # This await should not hang.
      page.click 'a'
    end

    it 'should click the button inside an iframe' do
      await page.goto server.domain
      await page.set_content '<div style="width:100px;height:100px">spacer</div>'
      attach_frame page, 'button-test', server.domain + 'input/button.html'
      frame = page.frames[1]
      button = frame.query_selector 'button'
      button.click
      expect(await frame.evaluate 'window.result').to eq 'Clicked'
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
      expect(await page.evaluate 'window.devicePixelRatio').to eq 5
      await page.set_content '<div style="width:100px;height:100px">spacer</div>'
      attach_frame page, 'button-test', server.domain + 'input/button.html'
      frame = page.frames[1]
      button = frame.query_selector 'button'
      button.click
      expect(await frame.evaluate 'window.result').to eq 'Clicked'
    end
  end
end
