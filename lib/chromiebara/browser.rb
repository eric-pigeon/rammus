require 'forwardable'

module Chromiebara
  class Browser
    extend Forwardable
    attr_reader :client, :default_context

    delegate [:new_page] => :default_context

    def initialize(client:)
      @client = client
      @contexts = {}
      @default_context = BrowserContext.new(client: client, browser: self)
      @_targets = {}
      client.on('Target.targetCreated', method(:target_created))
      client.on('Target.targetDestroyed', method(:target_destroyed))
      client.command Protocol::Target.set_discover_targets discover: true
    end

    # Creates a new incognito browser context. This won't share cookies/cache
    # with other browser contexts.
    #
    # @return [Chromiebara::BrowserContext]
    #
    def create_context
      response = client.command(Protocol::Target.create_browser_context)
      context_id = response['result']['browserContextId']

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

    # TODO document this
    def delete_context(context)
      _response = client.command(Protocol::Target.dispose_browser_context(browser_context_id: context.id))
      @contexts.delete(context.id)
      true
    end

    # An array of all pages inside the Browser. In case of multiple browser
    # contexts, the method will return an array with all the pages in all
    # browser contexts. Non visible pages, such as "background_page", will not
    # be listed here.
    #
    # @return [Array<Chromiebara::Page>]
    #
    def pages
      browser_contexts.flat_map(&:pages)
    end

    # An array of all active targets inside the Browser. In case of multiple
    # browser contexts, the method will return an array with all the targets in
    # all browser contexts.
    #
    # @return [Array<Chromiebara::Target>]
    #
    def targets
      # return Array.from(this._targets.values()).filter(target => target._isInitialized);
      @_targets.values
    end

    def target
      #     return this.targets().find(target => target.type() === 'browser');
    end

    # TODO document
    #
    def create_page_in_context(context_id)
      response = client.command(Protocol::Target.create_target(url: 'about:blank', browser_context_id: context_id))
      target_id = response.dig "result", "targetId"
      target = @_targets.fetch target_id
      target.page
    end

    private

      def target_created(event)
        target_info = event["targetInfo"]
        browser_context_id = target_info["browserContextId"]
        context = if browser_context_id && @contexts.has_key?(browser_context_id)
                    @contexts[browser_context_id]
                  else
                    default_context
                  end

        # const target = new Target(targetInfo, context, () => this._connection.createSession(targetInfo), this._ignoreHTTPSErrors, this._defaultViewport, this._screenshotTaskQueue);
        target = Target.new(target_info, context, client)

        # assert(!this._targets.has(event.targetInfo.targetId), 'Target should not exist before targetCreated');
        @_targets[target_info["targetId"]] = target

        # if (await target._initializedPromise) {
        #   this.emit(Events.Browser.TargetCreated, target);
        #   context.emit(Events.BrowserContext.TargetCreated, target);
        # }
      end

      def target_destroyed(event)
        # target = @_targets[event["targetId"]]
        # target._initializedCallback(false);
        @_targets.delete(event["targetId"])
        # target._closedCallback();
        # if (await target._initializedPromise) {
        #   this.emit(Events.Browser.TargetDestroyed, target);
        #   target.browserContext().emit(Events.BrowserContext.TargetDestroyed, target);
        # }
      end
  end
end
