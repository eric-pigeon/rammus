module Chromiebara
  class Target
    attr_reader :target_info, :browser_context

    # @param {!Protocol.Target.TargetInfo} targetInfo
    # @param {!Puppeteer.BrowserContext} browserContext
    # @param {!function():!Promise<!Puppeteer.CDPSession>} sessionFactory
    # @param {boolean} ignoreHTTPSErrors
    # @param {?Puppeteer.Viewport} defaultViewport
    # @param {!Puppeteer.TaskQueue} screenshotTaskQueue
    #
    def initialize(target_info, browser_context, client)
      @target_info = target_info
      @browser_context = browser_context
      @_client = client
    end

    # If the target is not of type "page" or "background_page", returns null.
    #
    # @return [Chromiebara::Page]
    #
    def page
      return unless type == "page" || type == "background_page"

      @_page ||= Page.new(@_client, self)
    # if ((this._targetInfo.type === 'page' || this._targetInfo.type === 'background_page') && !this._pagePromise) {
    #   this._pagePromise = this._sessionFactory()
    #       .then(client => Page.create(client, this, this._ignoreHTTPSErrors, this._defaultViewport, this._screenshotTaskQueue));
    # }
    # return this._pagePromise;
    end

    # Identifies what kind of target this is. Can be "page", "background_page",
    # "service_worker", "browser" or "other".
    #
    # @return [String]
    #
    def type
      types = ["page", "background_page", "service_worker", "browser"]
      if types.include? target_info["type"]
        target_info["type"]
      else
        "other"
      end
    end
  end
end
