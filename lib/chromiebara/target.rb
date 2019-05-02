module Chromiebara
  class Target
    attr_reader :target_info, :browser_context

    # @param [Hash] target_info
    # @param [Chromiebara::BrowserContext] browser_context
    # @param [Chromiebara::ChromeClient] client
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

      @_page ||= Page.new(self)
    end

    def session
      @_session ||= @_client.create_session target_info
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
