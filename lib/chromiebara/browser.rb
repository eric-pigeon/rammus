module Chromiebara
  class Browser
    extend Forwardable
    attr_reader :client, :default_context

    delegate [:new_page] => :default_context

    def initialize(client:)
      @client = client
      @contexts = {}
      @default_context = BrowserContext.new(client: client, browser: self)
    end

    # Creates a new incognito browser context. This won't share cookies/cache
    # with other browser contexts.
    #
    # @return [Chromiebara::BrowserContext]
    #
    def create_context
      response = client.command(Protocol::Target.create_browser_context)
      context_id = response['browserContextId']

      BrowserContext.new(client: client, id: context_id, browser: self).tap do |context|
        @contexts[context_id] = context
      end
    end

    # Returns an array of all open browser contexts. In a newly created browser,
    # this will return a single instance of BrowserContext.
    #
    # @return [Array<Chromiebara::BrowserContext>]
    #
    def browser_contexts
      [default_context, *@contexts.values]
    end

    # TODO
    def delete_context(context)
      _response = client.command(Protocol::Target.dispose_browser_context(browser_context_id: context.id))
      @contexts.delete(context.id)
      true
    end
  end
end
