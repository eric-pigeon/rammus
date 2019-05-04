module Chromiebara
  RSpec.describe BrowserContext do
    before do
      @browser = Launcher.launch
    end

    describe '#close' do
      it 'disposes of the context' do
        context = @browser.create_context
        expect(@browser.browser_contexts.size).to eq 2

        context.close
        expect(@browser.browser_contexts.size).to eq 1

        response = @browser.client.command Protocol::Target.get_browser_contexts
        expect(response["browserContextIds"].size).to eq 0
      end

      it 'fails without an id' do
        context = @browser.default_context

        expect { context.close }.to raise_error BrowserContext::UncloseableContext
      end

      it 'closes all children targets' do
        expect(@browser.pages.size).to eq 1

        context = @browser.create_context
        _page = context.new_page

        expect(@browser.pages.size).to eq 2
        expect(context.pages.size).to eq 1

        context.close

        expect(@browser.pages.size).to eq 1
        expect(@browser.targets.select { |target| target.type == "page" }.size).to eq 1
      end
    end

    describe '#new_page' do
      it 'creates a page' do
        expect(@browser.pages.size).to eq 1
        context = @browser.default_context

        _page = context.new_page

        expect(@browser.pages.size).to eq 2
      end
    end

    describe '#pages' do
      xit 'returns all open pages' do
        pending 'todo'
      end
    end

    describe '#targets' do
      xit 'returns all targets' do
        pending 'todo'
      end
    end
  end
end
