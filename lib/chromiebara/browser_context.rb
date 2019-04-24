module Chromiebara
  class BrowserContext
    class UncloseableContext < StandardError; end

    attr_reader :id, :browser, :client

    def initialize(browser:, client:, id: nil)
      @id = id
      @browser = browser
      @client = client
    end

    # Closes the browser context. All the targets that belong to the browser context will be closed.
    # All pages will be closed without calling their beforeunload hooks.
    #
    def close
      raise UncloseableContext unless id
      browser.delete_context(self)
    end
  end
end
