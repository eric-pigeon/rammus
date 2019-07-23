module Rammus
  RSpec.describe Touchscreen, browser: true do
    include Promise::Await
    before { @_context = browser.create_context }
    after { @_context.close }
    let(:context) { @_context }
    let!(:page) { context.new_page }

    it 'should tap the button' do
      page.emulate Rammus.devices['iPhone 6']
      await page.goto server.domain + 'input/button.html'
      page.touchscreen_tap 'button'
      expect(await page.evaluate 'result').to eq 'Clicked'
    end

    it 'should report touches' do
      page.emulate Rammus.devices['iPhone 6']
      await page.goto server.domain + 'input/touches.html'
      button = page.query_selector 'button'
      button.tap
      expect(await page.evaluate 'getResult()').to eq ['Touchstart: 0', 'Touchend: 0']
    end
  end
end
