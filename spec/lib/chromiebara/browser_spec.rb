module Chromiebara
  RSpec.describe Browser do
    before do
      @browser = Launcher.launch
    end

    describe '#create_browser_context' do
      it 'creates a new context' do
        context = @browser.create_context

        expect(context).to be_a Chromiebara::BrowserContext
      end
    end

    describe '#browser_contexts' do
      it 'returns all browser_contexts' do
        expect(@browser.browser_contexts.length).to eq 1

        @browser.create_context

        expect(@browser.browser_contexts.length).to eq 2
      end
    end

    describe '#close_context' do
      it 'deletes the context' do
        context = @browser.create_context

        expect(@browser.browser_contexts.size).to eq 2

        @browser.delete_context(context)

        expect(@browser.browser_contexts.size).to eq 1

        response = @browser.client.command Protocol::Target.get_browser_contexts
        expect(response["result"]["browserContextIds"].size).to eq 0
      end

      xit 'raises an error if the context does not exist' do
        context = BrowserContext.new(client: @browser.client, browser: @browser, id: "FAKEID")

        # TODO should raise a specific error here?
        expect do
          @browser.delete_context context
        end.to raise_error "Failed to find context with id FAKEID"
      end
    end
  end
end
