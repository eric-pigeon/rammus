require 'forwardable'

module Chromiebara
  class Browser
    include Promise::Await
    extend Forwardable
    attr_reader :client, :default_context

    delegate [:new_page] => :default_context

    def initialize(client:, close_callback: nil, ignore_https_errors: false, default_viewport: nil)
      @client = client
      @_ignore_https_errors = ignore_https_errors
      @_default_viewport = default_viewport
      @contexts = {}
      @default_context = BrowserContext.new(client: client, browser: self)
      @_close_callback = close_callback
      @_targets = {}
      client.on('Target.targetCreated', method(:target_created))
      client.on('Target.targetDestroyed', method(:target_destroyed))
      client.on('Target.targetInfoChanged', method(:target_info_changed))
      await client.command Protocol::Target.set_discover_targets discover: true
    end

    # Creates a new incognito browser context. This won't share cookies/cache
    # with other browser contexts.
    #
    # @return [Chromiebara::BrowserContext]
    #
    def create_context
      response = await client.command(Protocol::Target.create_browser_context)
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

    # TODO document this
    def delete_context(context)
      _response = await client.command(Protocol::Target.dispose_browser_context(browser_context_id: context.id))
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
      @_targets.values.select(&:initialized)
    end

    # The target associated with the browser.
    #
    # @return [Chromiebara::Target]
    #
    def target
      targets.detect { |target| target.type == "browser" }
    end

    # Creates a new page in the browser context
    #
    # @return [Chromiebara::Page]
    #
    def create_page_in_context(context_id)
      response = await client.command(Protocol::Target.create_target(url: 'about:blank', browser_context_id: context_id))
      target_id = response["targetId"]
      target = @_targets.fetch target_id
      target.page
    end

    # The browsers version information
    #
    # @return [Hash]
    #
    def version
      await client.command Protocol::Browser.get_version
    end

    # Closes the browser and all of its pages (if any were opened). The Browser
    # object itself is considered to be disposed and cannot be used anymore.
    #
    def close
      @_close_callback.call
      # TODO
      # client.disconnect
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
        target = Target.new(target_info, context, client, @_ignore_https_errors, @_default_viewport)

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

      def target_info_changed(event)
        target = @_targets.fetch event.dig("targetInfo", "targetId")
        previous_url = target.url
        was_initialized = target.initialized
        target.send(:target_info_changed, event["targetInfo"])
        # target._targetInfoChanged(event.targetInfo);

        if was_initialized && previous_url != target.url
          # this.emit(Events.Browser.TargetChanged, target);
          # target.browserContext().emit(Events.BrowserContext.TargetChanged, target);
        end
      end
  end
end
