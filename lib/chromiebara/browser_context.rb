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

    # Creates a new page in the browser context.
    #
    # @return [Chromiebara::Page]
    #
    def new_page
      browser.create_page_in_context(self.id)
    end

    # An array of all open pages. Non visible pages, such as "background_page",
    # will not be listed here. You can find them using target.page().
    # An array of all pages inside the browser context.
    #
    # @return [Array<Chromiebara::Page>]
    #
    def pages
      targets
        .select { |target| target.type == "page" }
        .map(&:page)
      # return pages.filter(page => !!page);
    end

    # An array of all active targets inside the browser context.
    #
    # @return [Array<Chromiebara::Target>]
    #
    def targets
      browser.targets.select { |target| target.browser_context == self }
    end

    # browserContext.clearPermissionOverrides()
    # browserContext.isIncognito()
    # browserContext.overridePermissions(origin, permissions)
    # browserContext.waitForTarget(predicate[, options])
  end
end
