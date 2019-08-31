module Rammus
  RSpec.describe BrowserContext, browser: true do
    include Promise::Await

    after(:each) do
      browser.browser_contexts.select(&:incognito?).each(&:close)
      browser.pages[1..-1]&.each(&:close)
    end

    describe '#close' do
      it 'disposes of the context' do
        context = browser.create_context
        expect(browser.browser_contexts.size).to eq 2

        context.close
        expect(browser.browser_contexts.size).to eq 1

        response = await browser.client.command Protocol::Target.get_browser_contexts
        expect(response["browserContextIds"].size).to eq 0
      end

      it 'fails without an id' do
        context = browser.default_context

        expect { context.close }.to raise_error BrowserContext::UncloseableContext
      end

      it 'closes all children targets' do
        expect(browser.pages.size).to eq 1

        context = browser.create_context
        _page = context.new_page

        expect(browser.pages.size).to eq 2
        expect(context.pages.size).to eq 1

        context.close

        expect(browser.pages.size).to eq 1
        expect(browser.targets.select { |target| target.type == "page" }.size).to eq 1
      end
    end

    describe '#new_page' do
      it 'creates a page' do
        expect(browser.pages.size).to eq 1
        context = browser.default_context

        _page = context.new_page

        expect(browser.pages.size).to eq 2
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