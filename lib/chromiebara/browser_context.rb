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

    def new_page
      client.command(Protocol::Target.create_target(url: 'about:blank', browser_context_id: id))
    end

    # browserContext.clearPermissionOverrides()
    # browserContext.isIncognito()
    # browserContext.newPage()
    # browserContext.overridePermissions(origin, permissions)
    # browserContext.pages()
    # browserContext.targets()
    # browserContext.waitForTarget(predicate[, options])
  end
end
