# frozen_string_literal: true

module Rammus
  class Target
    extend Forwardable
    # @!visibility private
    attr_reader :target_info, :target_id, :initialized, :initialized_promise,
      :initialized_callback, :_closed_callback, :is_closed_promise,
      :_page_promise,
      :_page

    # The browser context the target belongs to.
    #
    # @return [Rammus::BrowserContext]
    #
    attr_reader :browser_context

    # @!method browser
    #   The browser the target belongs to
    #
    #   @return [Rammus::Browser]
    #
    delegate [:browser] => :browser_context

    # @!visibility private
    #
    # @param target_info [Hash]
    # @param browser_context [Rammus::BrowserContext]
    # @param client [Rammus::ChromeClient]
    #
    def initialize(target_info, browser_context, client, ignore_https_errors, default_viewport)
      @target_info = target_info
      @browser_context = browser_context
      @target_id = target_info["targetId"]
      # session factory
      @_ignore_https_errors = ignore_https_errors
      @_default_viewport = default_viewport
      # screenshot task queue
      @_page_promise = nil
      @_worker_promise = nil
      @_client = client

      initialized_promise = Concurrent::Promises.resolvable_future
      @initialized_callback = initialized_promise.method(:fulfill)
      @initialized_promise = initialized_promise.then do |success|
        next false unless success

        if !opener || !opener._page || type != 'page'
          next true
        end

        opener_page = opener._page

        next true if opener_page.listener_count(:popup).zero?

        popup_page = page
        opener_page.emit :popup, popup_page
        true
      end

      @is_closed_promise = Concurrent::Promises.resolvable_future
      @_closed_callback = @is_closed_promise.method(:fulfill)
      @initialized = target_info["type"] != 'page' || target_info["url"] != ""
      @initialized_callback.(true) if initialized
    end

    # The target that opened this target. Top-level targets return nil
    #
    # @return [Target, nil]
    #
    def opener
      return unless (opener_id = target_info["openerId"])

      # TODO
      browser.instance_variable_get(:@_targets)[opener_id]
    end

    # If the target is not of type "page" or "background_page", returns nil
    #
    # @return [Rammus::Page, nil]
    #
    def page
      return unless type == "page" || type == "background_page"

      @_page ||= Page.create(self, ignore_https_errors: @_ignore_https_errors, default_viewport: @_default_viewport)
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

    # @return [Rammus::CDPSession]
    #
    def session
      @_session ||= @_client.create_session target_info
    end

    # Targer url
    #
    # @return [String]
    #
    def url
      target_info["url"]
    end

    # If the target is not of type "service_worker" or "shared_worker", returns
    #   nil.
    #
    # @return [Worker, nil]
    #
    def worker
      return if type != 'service_worker' || type != 'shared_worker'
      # if (!this._workerPromise) {
      #  this._workerPromise = this._sessionFactory().then(async client => {
      #    // Top level workers have a fake page wrapping the actual worker.
      #    const [targetAttached] = await Promise.all([
      #      new Promise(x => client.once('Target.attachedToTarget', x)),
      #      client.send('Target.setAutoAttach', {autoAttach: true, waitForDebuggerOnStart: false, flatten: true}),
      #    ]);
      #    const session = Connection.fromSession(client).session(targetAttached.sessionId);
      #    // TODO(einbinder): Make workers send their console logs.
      #    return new Worker(session, this._targetInfo.url, () => {} /* consoleAPICalled */, () => {} /* exceptionThrown */);
      #  });
      # }
      # return this._workerPromise;
    end

    def inspect
      "#<#{self.class}:0x#{object_id} #{target_info}>"
    end

    private

      # @param target_info [Hash]
      #
      def target_info_changed(target_info)
        @target_info = target_info

        return unless !initialized && (target_info["type"] != "page" || target_info["url"] != "")

        @initialized = true
        @initialized_callback.(true)
      end
  end
end
