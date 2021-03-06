# frozen_string_literal: true

require 'forwardable'

module Rammus
  # A Browser is created when Rammus connects to a Chromium instance, either
  # through {Rammus.launch} or {Rammus.connect}.
  #
  class Browser
    include EventEmitter
    extend Forwardable
    attr_reader :client, :default_context

    # @!method new_page
    #   (see Rammus::BrowserContext#new_page)
    delegate [:new_page] => :default_context

    # @!visibility private
    #
    def initialize(client:, context_ids: [], close_callback: nil, ignore_https_errors: false, default_viewport: nil)
      super()
      @client = client
      @_ignore_https_errors = ignore_https_errors
      @_default_viewport = default_viewport
      @contexts = {}
      context_ids.each do |context_id|
        @contexts[context_id] = BrowserContext.new(client: client, browser: self, id: context_id)
      end

      @default_context = BrowserContext.new(client: client, browser: self)
      @_close_callback = close_callback
      @_targets = Concurrent::Hash.new
      client.on Protocol::Target.target_created, method(:target_created)
      client.on Protocol::Target.target_destroyed, method(:target_destroyed)
      client.on Protocol::Target.target_info_changed, method(:target_info_changed)
      client.command(Protocol::Target.set_discover_targets(discover: true)).wait!
    end

    # Creates a new incognito browser context. This won't share cookies/cache
    # with other browser contexts.
    #
    # @return [Rammus::BrowserContext]
    #
    def create_context
      response = client.command(Protocol::Target.create_browser_context).value
      context_id = response['browserContextId']

      BrowserContext.new(client: client, id: context_id, browser: self).tap do |context|
        @contexts[context_id] = context
      end
    end

    # Returns an array of all open browser contexts. In a newly created browser,
    # this will return a single instance of {BrowserContext}.
    #
    # @return [Array<Rammus::BrowserContext>]
    #
    def browser_contexts
      [default_context, *@contexts.values]
    end

    # An array of all pages inside the Browser. In case of multiple browser
    # contexts, the method will return an array with all the pages in all
    # browser contexts. Non visible pages, such as "background_page", will not
    # be listed here.
    #
    # @return [Array<Rammus::Page>]
    #
    def pages
      browser_contexts.flat_map(&:pages)
    end

    # An array of all active targets inside the Browser. In case of multiple
    # browser contexts, the method will return an array with all the targets in
    # all browser contexts.
    #
    # @return [Array<Rammus::Target>]
    #
    def targets
      @_targets.values.select(&:initialized)
    end

    # The target associated with the browser.
    #
    # @return [Rammus::Target]
    #
    def target
      targets.detect { |target| target.type == "browser" }
    end

    # Search for a target in all contexts.
    #
    # @overload wait_for_target(timeout: 2, predicate:)
    #   @param timeout [Integer] Maximum wait time in milliseconds. Pass 0 to disable the timeout. Defaults to 2 seconds.
    #   @param predicate [#call:Boolean] A callable to be run for every target
    #
    # @overload wait_for_target(timeout: 2, &block)
    #   @param timeout [Integer] Maximum wait time in milliseconds. Pass 0 to disable the timeout. Defaults to 2 seconds.
    #   @yield [Rammus::Target] A block to detect the target
    #
    # @return [Promise<Target>]
    #
    def wait_for_target(timeout: 2, predicate: nil, &block)
      predicate ||= block

      existing_target = targets.detect(&predicate)
      return Concurrent::Promises.fulfilled_future(existing_target) unless existing_target.nil?

      target_promise = Concurrent::Promises.resolvable_future

      check = ->(target) do
        target_promise.fulfill(target) if predicate.(target)
      end

      on :target_created, check
      on :target_changed, check

      Concurrent::Promises.future do
        Util.wait_with_timeout(target_promise, "target", timeout).value!
      ensure
        remove_listener :target_created, check
        remove_listener :target_changed, check
      end
    end

    # The browsers version information
    #
    # @return [Hash]
    #
    def version
      client.command(Protocol::Browser.get_version).value
    end

    # Closes the browser and all of its pages (if any were opened). The Browser
    # object itself is considered to be disposed and cannot be used anymore.
    #
    def close
      Concurrent::Promises.future do
        @_close_callback.call
        disconnect
      end
    end

    # Disconnects Rammus from the browser, but leaves the Chromium process
    # running. After calling disconnect, the Browser object is considered
    # disposed and cannot be used anymore.
    #
    def disconnect
      client.dispose
    end

    # @!visibility private
    #
    # @raise [Rammus::Errors::ProtocolError] raised if deleting browser context
    #   fails
    #
    def delete_context(context)
      _response = client.command(Protocol::Target.dispose_browser_context(browser_context_id: context.id)).value!
      @contexts.delete(context.id)
      true
    end

    # Creates a new page in the browser context
    #
    # @return [Rammus::Page]
    #
    # @!visibility private
    #
    def create_page_in_context(context_id)
      response = client.command(Protocol::Target.create_target(url: 'about:blank', browser_context_id: context_id)).value
      target_id = response["targetId"]
      target = wait_for_target { |t| t.target_id == target_id }.value!
      target.initialized_promise.wait!
      target.page
    end

    # return [String]
    #
    def ws_endpoint
      client.url
    end

    private

      def event_queue
        client.send :event_queue
      end

      def target_created(event)
        target_info = event["targetInfo"]
        browser_context_id = target_info["browserContextId"]
        context = if browser_context_id && @contexts.key?(browser_context_id)
                    @contexts[browser_context_id]
                  else
                    default_context
                  end

        target = Target.new(target_info, context, client, @_ignore_https_errors, @_default_viewport)

        # assert(!this._targets.has(event.targetInfo.targetId), 'Target should not exist before targetCreated');
        @_targets[target_info["targetId"]] = target

        target.initialized_promise.then do |success|
          next unless success

          emit :target_created, target
          context.emit :target_created, target
        end
      end

      def target_destroyed(event)
        target = @_targets.delete(event["targetId"])
        target.initialized_callback.(false, false)
        target._closed_callback.(nil)
        target.initialized_promise.then do |success|
          next unless success

          emit :target_destroyed, target
          target.browser_context.emit :target_destroyed, target
        end
      end

      def target_info_changed(event)
        target = @_targets.fetch event.dig("targetInfo", "targetId")
        previous_url = target.url
        was_initialized = target.initialized
        target.send(:target_info_changed, event["targetInfo"])

        return unless was_initialized && previous_url != target.url

        emit :target_changed, target
        target.browser_context.emit :target_changed, target
      end
  end
end
