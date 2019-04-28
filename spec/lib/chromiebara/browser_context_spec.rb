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
        expect(response["result"]["browserContextIds"].size).to eq 0
      end

      it 'fails without an id' do
        context = @browser.default_context

        expect do
          context.close
        end.to raise_error BrowserContext::UncloseableContext
      end
    end

    describe '#new_page' do
      it 'creates a page' do
        context = @browser.default_context
        @browser.client.command Protocol::Target.get_browser_contexts

        _page = context.new_page

        # TODO
        # while true
        #   puts context.client.web_socket.read_message
        # end
      end
    end

    # it('should close all belonging targets once closing context', async function({browser, server}) {
    #   expect((await browser.pages()).length).toBe(1);

    #   const context = await browser.createIncognitoBrowserContext();
    #   await context.newPage();
    #   expect((await browser.pages()).length).toBe(2);
    #   expect((await context.pages()).length).toBe(1);

    #   await context.close();
    #   expect((await browser.pages()).length).toBe(1);
    # });
  end
end
