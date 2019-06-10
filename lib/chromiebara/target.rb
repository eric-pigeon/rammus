module Chromiebara
  class Target
    attr_reader :target_info, :browser_context, :target_id, :initialized,
      :initialized_promise, :initialized_callback, :_closed_callback

    # @param [Hash] target_info
    # @param [Chromiebara::BrowserContext] browser_context
    # @param [Chromiebara::ChromeClient] client
    #
    def initialize(target_info, browser_context, client, ignore_https_errors, default_viewport)
      @target_info = target_info
      @browser_context = browser_context
      @_ignore_https_errors = ignore_https_errors
      @_default_viewport = default_viewport
      @target_id = target_info["targetId"]
      @_client = client

      initialized_promise, @initialized_callback, _reject = Promise.create
      @initialized_promise = initialized_promise.then do |success|
        next false unless success
        #const opener = this.opener();
        #if (!opener || !opener._pagePromise || this.type() !== 'page')
        #  return true;
        #const openerPage = await opener._pagePromise;
        #if (!openerPage.listenerCount(Events.Page.Popup))
        #  return true;
        #const popupPage = await this.page();
        #openerPage.emit(Events.Page.Popup, popupPage);
        true
      end

      @_is_closed_promise, @_closed_callback, _ = Promise.create
      @initialized = target_info["type"] != 'page' || target_info["url"] != ""
      @initialized_callback.(true) if initialized
    end

    # If the target is not of type "page" or "background_page", returns null.
    #
    # @return [Chromiebara::Page]
    #
    def page
      return unless type == "page" || type == "background_page"

      @_page ||= Page.create(self, ignore_https_errors: @_ignore_https_errors, default_viewport: @_default_viewport)
    end

    def worker
      return if type != 'service_worker' || type != 'shared_worker'
      #if (!this._workerPromise) {
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
      #}
      #return this._workerPromise;
    end

    def session
      @_session ||= @_client.create_session target_info
    end

    # @return [String]
    #
    def url
      target_info["url"]
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

    private

      # @param [Hash] target_info
      #
      def target_info_changed(target_info)
        @target_info = target_info

        if !initialized && (target_info["type"] != "page" || target_info["url"] != "")
          @initialized = true
          @initialized_callback.(true)
        end
      end
  end
end
