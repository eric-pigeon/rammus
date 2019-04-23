module Chromiebara
  class Browser
    attr_reader :client

    def initialize(client:)
      @client = client
    end

    # Returns an array of all open browser contexts. In a newly created browser,
    # this will return a single instance of BrowserContext.
    #
    # @return [Array<Chromiebara::BrowserContext>]
    #
    def browser_contexts
      client.command(Protocol::Target.get_browser_contexts)
    end

    private
  end
end
