module Chromiebara
  RSpec.describe Browser do
    before do
      @browser = Launcher.launch(headless: false)
    end

    describe '#browser_contexts' do
      it 'returns all browser_contexts' do
        expect(@browser.browser_contexts).to be_empty

        @browser.create_context

        expect(@browser.browser_contexts).not_to be_empty
      end
    end
  end
end
