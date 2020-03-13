module Rammus
  RSpec.describe Touchscreen, browser: true do
    before { @_context = browser.create_context }
    after { @_context.close }
    let(:context) { @_context }
    let!(:page) { context.new_page }

    it 'should tap the button' do
      page.emulate Rammus.devices['iPhone 6']
      page.goto(server.domain + 'input/button.html').wait!
      page.touchscreen_tap 'button'
      expect(page.evaluate('result').value!).to eq 'Clicked'
    end

    it 'should report touches' do
      page.emulate Rammus.devices['iPhone 6']
      page.goto(server.domain + 'input/touches.html').wait!
      button = page.query_selector 'button'
      button.tap
      expect(page.evaluate('getResult()').value!).to eq ['Touchstart: 0', 'Touchend: 0']
    end
  end
end
