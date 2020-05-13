# frozen_string_literal: true

module Rammus
  RSpec.describe Browser, browser: true do
    after(:each) do
      browser.browser_contexts.select(&:incognito?).each(&:close)
      browser.pages[1..-1].each(&:close)
    end

    describe '#create_browser_context' do
      it 'creates a new context' do
        context = browser.create_context

        expect(context).to be_a Rammus::BrowserContext
      end
    end

    describe '#browser_contexts' do
      it 'returns all browser_contexts' do
        expect(browser.browser_contexts.length).to eq 1

        browser.create_context

        expect(browser.browser_contexts.length).to eq 2
      end
    end

    describe '#delete_context' do
      it 'deletes the context' do
        context = browser.create_context

        expect(browser.browser_contexts.size).to eq 2

        browser.delete_context(context)

        expect(browser.browser_contexts.size).to eq 1

        response = browser.client.command(Protocol::Target.get_browser_contexts).value
        expect(response["browserContextIds"].size).to eq 0
      end

      it 'raises an error if the context does not exist' do
        context = BrowserContext.new(client: browser.client, browser: browser, id: "FAKEID")

        expect { browser.delete_context context }
          .to raise_error(/Failed to find context with id FAKEID/)
      end
    end

    describe '#target' do
      it 'retuns the target for the browser' do
        target = browser.target

        expect(target.type).to eq "browser"
      end
    end

    describe '#version' do
      it 'returns the browser version' do
        version = browser.version

        expect(version).to be_a Hash
      end
    end

    describe '#close' do
      it 'should terminate network waiters' do
        new_browser = Rammus.launch
        remote = Rammus.connect ws_endpoint: new_browser.ws_endpoint
        new_page = remote.new_page

        results = Concurrent::Promises.zip(
          new_page.wait_for_request(server.empty_page).rescue { |e| e },
          new_page.wait_for_response(server.empty_page).rescue { |e| e },
          new_browser.close
        ).value!

        results.take(2).each do |result|
          expect(result.message).to include 'Target closed'
          expect(result.message).not_to include 'Timeout'
        end
      end
    end
  end
end
