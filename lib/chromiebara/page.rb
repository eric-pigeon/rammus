require 'chromiebara/accessibility'
require 'chromiebara/keyboard'
require 'chromiebara/mouse'
require 'chromiebara/touchscreen'
require 'chromiebara/dialog'
require 'chromiebara/frame_manager'
require 'chromiebara/emulation_manager'
require 'Chromiebara/timeout_settings'

module Chromiebara
  class Page
    include Promise::Await
    include EventEmitter
    extend Promise::Await
    extend Forwardable

    attr_reader :target, :frame_manager, :javascript_enabled, :keyboard, :mouse, :touchscreen, :accessibility
    delegate [:url] => :main_frame

    def self.create(target, default_viewport: nil)
      new(target).tap do |page|
        await Promise.all(
          page.frame_manager.start,
          target.session.command(Protocol::Target.set_auto_attach auto_attach: true, wait_for_debugger_on_start: false, flatten: true),
          target.session.command(Protocol::Performance.enable),
          target.session.command(Protocol::Log.enable),
        )
        if default_viewport
          page.set_viewport default_viewport
        end
      end
    end

    private_class_method :new
    def initialize(target)
      super()
      @_closed = false
      @target = target
      @keyboard = Keyboard.new client
      @mouse =  Mouse.new client, keyboard
      @_timeoutSettings =  TimeoutSettings.new
      @touchscreen = Touchscreen.new client, keyboard
      @accessibility = Accessibility.new client
      # TODO ignore_https_errors
      @frame_manager = FrameManager.new(client, self, false)
      # this._frameManager = new FrameManager(client, this, ignoreHTTPSErrors, this._timeoutSettings);
      @_emulation_manager = EmulationManager.new client
      # this._tracing = new Tracing(client);
      # /** @type {!Map<string, Function>} */
      # this._pageBindings = new Map();
      # this._coverage = new Coverage(client);
      @javascript_enabled = true
      # /** @type {?Puppeteer.Viewport} */
      @_viewport = nil

      # this._screenshotTaskQueue = screenshotTaskQueue;

      # /** @type {!Map<string, Worker>} */
      # this._workers = new Map();
      client.on Protocol::Target.attached_to_target, -> (event) { raise 'todo' }
      # client.on('Target.attachedToTarget', event => {
      #   if (event.targetInfo.type !== 'worker') {
      #     // If we don't detach from service workers, they will never die.
      #     client.send('Target.detachFromTarget', {
      #       sessionId: event.sessionId
      #     }).catch(debugError);
      #     return;
      #   }
      #   const session = Connection.fromSession(client).session(event.sessionId);
      #   const worker = new Worker(session, event.targetInfo.url, this._addConsoleMessage.bind(this), this._handleException.bind(this));
      #   this._workers.set(event.sessionId, worker);
      #   this.emit(Events.Page.WorkerCreated, worker);
      # });
      # client.on('Target.detachedFromTarget', event => {
      #   const worker = this._workers.get(event.sessionId);
      #   if (!worker)
      #     return;
      #   this.emit(Events.Page.WorkerDestroyed, worker);
      #   this._workers.delete(event.sessionId);
      # });

      # this._frameManager.on(Events.FrameManager.FrameAttached, event => this.emit(Events.Page.FrameAttached, event));
      # this._frameManager.on(Events.FrameManager.FrameDetached, event => this.emit(Events.Page.FrameDetached, event));
      # this._frameManager.on(Events.FrameManager.FrameNavigated, event => this.emit(Events.Page.FrameNavigated, event));

      # const networkManager = this._frameManager.networkManager();
      # networkManager.on(Events.NetworkManager.Request, event => this.emit(Events.Page.Request, event));
      # networkManager.on(Events.NetworkManager.Response, event => this.emit(Events.Page.Response, event));
      # networkManager.on(Events.NetworkManager.RequestFailed, event => this.emit(Events.Page.RequestFailed, event));
      # networkManager.on(Events.NetworkManager.RequestFinished, event => this.emit(Events.Page.RequestFinished, event));

      # client.on('Page.domContentEventFired', event => this.emit(Events.Page.DOMContentLoaded));
      # client.on('Page.loadEventFired', event => this.emit(Events.Page.Load));
      # client.on('Runtime.consoleAPICalled', event => this._onConsoleAPI(event));
      # client.on('Runtime.bindingCalled', event => this._onBindingCalled(event));
      client.on Protocol::Page.javascript_dialog_opening, method(:on_dialog)
      # client.on('Runtime.exceptionThrown', exception => this._handleException(exception.exceptionDetails));
      # client.on('Inspector.targetCrashed', event => this._onTargetCrashed());
      # client.on('Performance.metrics', event => this._emitMetrics(event));
      # client.on('Log.entryAdded', event => this._onLogEntryAdded(event));
      # this._target._isClosedPromise.then(() => {
      #   this.emit(Events.Page.Close);
      #   this._closed = true;
      # });
    end

    # @return {!Puppeteer.Browser}
    #
    def browser
      target.browser
    end

    # @return {!Puppeteer.BrowserContext}
    #
    def browser_context
      target.browser_context
    end

    # @return [Chromiebara::Frame]
    #
    def main_frame
      @frame_manager.main_frame
    end

  # async setGeolocation(options) {
  #   const { longitude, latitude, accuracy = 0} = options;
  #   if (longitude < -180 || longitude > 180)
  #     throw new Error(`Invalid longitude "${longitude}": precondition -180 <= LONGITUDE <= 180 failed.`);
  #   if (latitude < -90 || latitude > 90)
  #     throw new Error(`Invalid latitude "${latitude}": precondition -90 <= LATITUDE <= 90 failed.`);
  #   if (accuracy < 0)
  #     throw new Error(`Invalid accuracy "${accuracy}": precondition 0 <= ACCURACY failed.`);
  #   await this._client.send('Emulation.setGeolocationOverride', {longitude, latitude, accuracy});
  # }

    # @return [Chromiebara::Browser]
    #
    def browser
      target.browser
    end

  # /**
  #  * @return {!Touchscreen}
  #  */
  # get touchscreen() {
  #   return this._touchscreen;
  # }

  # /**
  #  * @return {!Coverage}
  #  */
  # get coverage() {
  #   return this._coverage;
  # }

  # /**
  #  * @return {!Tracing}
  #  */
  # get tracing() {
  #   return this._tracing;
  # }

    # An array of all frames attached to the page
    #
    # @return [<Chromiebara::Frame>]
    #
    def frames
      @frame_manager.frames
    end

  # /**
  #  * @return {!Array<!Worker>}
  #  */
  # workers() {
  #   return Array.from(this._workers.values());
  # }

  # /**
  #  * @param {boolean} value
  #  */
  # async setRequestInterception(value) {
  #   return this._frameManager.networkManager().setRequestInterception(value);
  # }

  # /**
  #  * @param {boolean} enabled
  #  */
  # setOfflineMode(enabled) {
  #   return this._frameManager.networkManager().setOfflineMode(enabled);
  # }

  # /**
  #  * @param {number} timeout
  #  */
  # setDefaultNavigationTimeout(timeout) {
  #   this._timeoutSettings.setDefaultNavigationTimeout(timeout);
  # }

  # /**
  #  * @param {number} timeout
  #  */
  # setDefaultTimeout(timeout) {
  #   this._timeoutSettings.setDefaultTimeout(timeout);
  # }

    # @param {string} selector
    # @return {!Promise<?Puppeteer.ElementHandle>}
    #
    def query_selector(selector)
      main_frame.query_selector selector
    end

    # @param {Function|string} pageFunction
    # @param {!Array<*>} args
    #  @return {!Promise<!Puppeteer.JSHandle>}
    #
    def evaluate_handle(page_function, *args)
      context = main_frame.execution_context
      context.evaluate_handle page_function, *args
    end

    # @param {Function|string} page_function
    # @param {!Array<*>} args
    #  @return {!Promise<!Puppeteer.JSHandle>}
    #
    def evaluate_handle_function(page_function, *args)
      context = main_frame.execution_context
      context.evaluate_handle_function page_function, *args
    end

  # /**
  #  * @param {!Puppeteer.JSHandle} prototypeHandle
  #  * @return {!Promise<!Puppeteer.JSHandle>}
  #  */
  # async queryObjects(prototypeHandle) {
  #   const context = await this.mainFrame().executionContext();
  #   return context.queryObjects(prototypeHandle);
  # }

    # @param {string} selector
    # @param {Function|string} pageFunction
    # @param {!Array<*>} args
    # @return {!Promise<(!Object|undefined)>}
    #
    def query_selector_evaluate_function(selector, page_function, *args)
      main_frame.query_selector_evaluate_function selector, page_function, *args
    end

  # /**
  #  * @param {string} selector
  #  * @param {Function|string} pageFunction
  #  * @param {!Array<*>} args
  #  * @return {!Promise<(!Object|undefined)>}
  #  */
  # async $$eval(selector, pageFunction, ...args) {
  #   return this.mainFrame().$$eval(selector, pageFunction, ...args);
  # }

  # /**
  #  * @param {string} selector
  #  * @return {!Promise<!Array<!Puppeteer.ElementHandle>>}
  #  */
  # async $$(selector) {
  #   return this.mainFrame().$$(selector);
  # }

  # /**
  #  * @param {string} expression
  #  * @return {!Promise<!Array<!Puppeteer.ElementHandle>>}
  #  */
  # async $x(expression) {
  #   return this.mainFrame().$x(expression);
  # }

    # If no URLs are specified, this method returns cookies for the current page
    # URL. If URLs are specified, only cookies for those URLs are returned.
    #
    # @param [Array<String>] urls
    #
    # @return [Array<Chromiebara::Network::Cookie>]
    #
    def cookies(*urls)
      urls = urls.length.zero? ? nil : urls
      response = await client.command Protocol::Network.get_cookies urls: urls
      response["cookies"]
    end

  #* @param {Array<Protocol.Network.deleteCookiesParameters>} cookies
  #
  def delete_cookie(*cookies)
    page_url = url
    cookies.each do |cookie|
      cookie ||= {}
      if !cookie.has_key?(:url) && page_url.start_with?("http")
        cookie[:url] = page_url
      end
      # TODO Hash#transform_keys was added in ruby 2.5
      cookie = cookie.map do |key, value|
        key = key.to_sym rescue key
        next unless [:name, :url, :domain, :path].include? key
        [key, value]
      end.compact.to_h
      await client.command Protocol::Network.delete_cookies cookie
    end
  end

  #  * @param {Array<Network.CookieParam>} cookies
  #
  def set_cookie(*cookies)
    page_url = url
    starts_with_http = page_url.start_with? 'http'
    cookies = cookies.map do |cookie|
      if !cookie.has_key?(:url) && starts_with_http
        cookie[:url] = page_url
      end
      if cookie[:url] == "about:blank"
        raise "Blank page can not have cookie \"#{cookie[:name]}\""
      end
      if cookie[:url] && cookie[:url].start_with?("data:")
        raise "Data URL can not have cookie \"#{cookie[:name]}\""
      end
      cookie
    end
    delete_cookie(*cookies)
    if cookies.length
      await client.command Protocol::Network.set_cookies cookies: cookies
    end
  end

    # @return {!Promise<!Puppeteer.ElementHandle>}
    #
    def add_script_tag(url: nil, path: nil, content: nil, type: nil)
      main_frame.add_script_tag url: url, path: path, content: content, type: type
    end

  # /**
  #  * @param {!{url?: string, path?: string, content?: string}} options
  #  * @return {!Promise<!Puppeteer.ElementHandle>}
  #  */
  # async addStyleTag(options) {
  #   return this.mainFrame().addStyleTag(options);
  # }

  # /**
  #  * @param {string} name
  #  * @param {Function} puppeteerFunction
  #  */
  # async exposeFunction(name, puppeteerFunction) {
  #   if (this._pageBindings.has(name))
  #     throw new Error(`Failed to add page binding with name ${name}: window['${name}'] already exists!`);
  #   this._pageBindings.set(name, puppeteerFunction);

  #   const expression = helper.evaluationString(addPageBinding, name);
  #   await this._client.send('Runtime.addBinding', {name: name});
  #   await this._client.send('Page.addScriptToEvaluateOnNewDocument', {source: expression});
  #   await Promise.all(this.frames().map(frame => frame.evaluate(expression).catch(debugError)));

  #   function addPageBinding(bindingName) {
  #     const binding = window[bindingName];
  #     window[bindingName] = (...args) => {
  #       const me = window[bindingName];
  #       let callbacks = me['callbacks'];
  #       if (!callbacks) {
  #         callbacks = new Map();
  #         me['callbacks'] = callbacks;
  #       }
  #       const seq = (me['lastSeq'] || 0) + 1;
  #       me['lastSeq'] = seq;
  #       const promise = new Promise((resolve, reject) => callbacks.set(seq, {resolve, reject}));
  #       binding(JSON.stringify({name: bindingName, seq, args}));
  #       return promise;
  #     };
  #   }
  # }

  # /**
  #  * @param {?{username: string, password: string}} credentials
  #  */
  # async authenticate(credentials) {
  #   return this._frameManager.networkManager().authenticate(credentials);
  # }

  # /**
  #  * @param {!Object<string, string>} headers
  #  */
  # async setExtraHTTPHeaders(headers) {
  #   return this._frameManager.networkManager().setExtraHTTPHeaders(headers);
  # }

    # @param [String] user_agent
    #
    def set_user_agent(user_agent)
      frame_manager.network_manager.set_user_agent user_agent
    end

  # /**
  #  * @return {!Promise<!Metrics>}
  #  */
  # async metrics() {
  #   const response = await this._client.send('Performance.getMetrics');
  #   return this._buildMetricsObject(response.metrics);
  # }

  # /**
  #  * @param {!Protocol.Performance.metricsPayload} event
  #  */
  # _emitMetrics(event) {
  #   this.emit(Events.Page.Metrics, {
  #     title: event.title,
  #     metrics: this._buildMetricsObject(event.metrics)
  #   });
  # }

  # /**
  #  * @param {?Array<!Protocol.Performance.Metric>} metrics
  #  * @return {!Metrics}
  #  */
  # _buildMetricsObject(metrics) {
  #   const result = {};
  #   for (const metric of metrics || []) {
  #     if (supportedMetrics.has(metric.name))
  #       result[metric.name] = metric.value;
  #   }
  #   return result;
  # }

  # /**
  #  * @param {!Protocol.Runtime.ExceptionDetails} exceptionDetails
  #  */
  # _handleException(exceptionDetails) {
  #   const message = helper.getExceptionMessage(exceptionDetails);
  #   const err = new Error(message);
  #   err.stack = ''; // Don't report clientside error with a node stack attached
  #   this.emit(Events.Page.PageError, err);
  # }

  # /**
  #  * @param {!Protocol.Runtime.consoleAPICalledPayload} event
  #  */
  # async _onConsoleAPI(event) {
  #   if (event.executionContextId === 0) {
  #     // DevTools protocol stores the last 1000 console messages. These
  #     // messages are always reported even for removed execution contexts. In
  #     // this case, they are marked with executionContextId = 0 and are
  #     // reported upon enabling Runtime agent.
  #     //
  #     // Ignore these messages since:
  #     // - there's no execution context we can use to operate with message
  #     //   arguments
  #     // - these messages are reported before Puppeteer clients can subscribe
  #     //   to the 'console'
  #     //   page event.
  #     //
  #     // @see https://github.com/GoogleChrome/puppeteer/issues/3865
  #     return;
  #   }
  #   const context = this._frameManager.executionContextById(event.executionContextId);
  #   const values = event.args.map(arg => createJSHandle(context, arg));
  #   this._addConsoleMessage(event.type, values, event.stackTrace);
  # }

  # /**
  #  * @param {!Protocol.Runtime.bindingCalledPayload} event
  #  */
  # async _onBindingCalled(event) {
  #   const {name, seq, args} = JSON.parse(event.payload);
  #   let expression = null;
  #   try {
  #     const result = await this._pageBindings.get(name)(...args);
  #     expression = helper.evaluationString(deliverResult, name, seq, result);
  #   } catch (error) {
  #     if (error instanceof Error)
  #       expression = helper.evaluationString(deliverError, name, seq, error.message, error.stack);
  #     else
  #       expression = helper.evaluationString(deliverErrorValue, name, seq, error);
  #   }
  #   this._client.send('Runtime.evaluate', { expression, contextId: event.executionContextId }).catch(debugError);

  #   /**
  #    * @param {string} name
  #    * @param {number} seq
  #    * @param {*} result
  #    */
  #   function deliverResult(name, seq, result) {
  #     window[name]['callbacks'].get(seq).resolve(result);
  #     window[name]['callbacks'].delete(seq);
  #   }

  #   /**
  #    * @param {string} name
  #    * @param {number} seq
  #    * @param {string} message
  #    * @param {string} stack
  #    */
  #   function deliverError(name, seq, message, stack) {
  #     const error = new Error(message);
  #     error.stack = stack;
  #     window[name]['callbacks'].get(seq).reject(error);
  #     window[name]['callbacks'].delete(seq);
  #   }

  #   /**
  #    * @param {string} name
  #    * @param {number} seq
  #    * @param {*} value
  #    */
  #   function deliverErrorValue(name, seq, value) {
  #     window[name]['callbacks'].get(seq).reject(value);
  #     window[name]['callbacks'].delete(seq);
  #   }
  # }

  # /**
  #  * @param {string} type
  #  * @param {!Array<!Puppeteer.JSHandle>} args
  #  * @param {Protocol.Runtime.StackTrace=} stackTrace
  #  */
  # _addConsoleMessage(type, args, stackTrace) {
  #   if (!this.listenerCount(Events.Page.Console)) {
  #     args.forEach(arg => arg.dispose());
  #     return;
  #   }
  #   const textTokens = [];
  #   for (const arg of args) {
  #     const remoteObject = arg._remoteObject;
  #     if (remoteObject.objectId)
  #       textTokens.push(arg.toString());
  #     else
  #       textTokens.push(helper.valueFromRemoteObject(remoteObject));
  #   }
  #   const location = stackTrace && stackTrace.callFrames.length ? {
  #     url: stackTrace.callFrames[0].url,
  #     lineNumber: stackTrace.callFrames[0].lineNumber,
  #     columnNumber: stackTrace.callFrames[0].columnNumber,
  #   } : {};
  #   const message = new ConsoleMessage(type, textTokens.join(' '), args, location);
  #   this.emit(Events.Page.Console, message);
  # }

    # * @return {!Promise<string>}
    #
    def content
      frame_manager.main_frame.content
    end

    # @param {string} html
    # @param {!{timeout?: number, waitUntil?: string|!Array<string>}=} options
    #
    def set_content(html, timeout: nil, wait_until: nil)
      frame_manager.main_frame.set_content html, timeout: timeout, wait_until: wait_until
    end

    # @param [String] url
    # TODO
    #
    def goto(url, referrer: nil, timeout: nil, wait_until: nil)
      main_frame.goto url, referrer: referrer, timeout: timeout, wait_until: wait_until
    end

    # @param {!{timeout?: number, waitUntil?: string|!Array<string>}=} options
    # @return {!Promise<?Puppeteer.Response>}
    #
    def reload(options = {})
      # TODO
    #   const [response] = await Promise.all([
    #     this.waitForNavigation(options),
    #     this._client.send('Page.reload')
    #   ]);
    #   return response;
    end

    # @param {!{timeout?: number, waitUntil?: string|!Array<string>}=} options
    # @return {!Promise<?Puppeteer.Response>}
    #
    def wait_for_navigation(options = {})
      # TODO
      await frame_manager.main_frame.wait_for_navigation options
    end

  # /**
  #  * @param {(string|Function)} urlOrPredicate
  #  * @param {!{timeout?: number}=} options
  #  * @return {!Promise<!Puppeteer.Request>}
  #  */
  # async waitForRequest(urlOrPredicate, options = {}) {
  #   const {
  #     timeout = this._timeoutSettings.timeout(),
  #   } = options;
  #   return helper.waitForEvent(this._frameManager.networkManager(), Events.NetworkManager.Request, request => {
  #     if (helper.isString(urlOrPredicate))
  #       return (urlOrPredicate === request.url());
  #     if (typeof urlOrPredicate === 'function')
  #       return !!(urlOrPredicate(request));
  #     return false;
  #   }, timeout);
  # }

  # /**
  #  * @param {(string|Function)} urlOrPredicate
  #  * @param {!{timeout?: number}=} options
  #  * @return {!Promise<!Puppeteer.Response>}
  #  */
  # async waitForResponse(urlOrPredicate, options = {}) {
  #   const {
  #     timeout = this._timeoutSettings.timeout(),
  #   } = options;
  #   return helper.waitForEvent(this._frameManager.networkManager(), Events.NetworkManager.Response, response => {
  #     if (helper.isString(urlOrPredicate))
  #       return (urlOrPredicate === response.url());
  #     if (typeof urlOrPredicate === 'function')
  #       return !!(urlOrPredicate(response));
  #     return false;
  #   }, timeout);
  # }

  # /**
  #  * @param {!{timeout?: number, waitUntil?: string|!Array<string>}=} options
  #  * @return {!Promise<?Puppeteer.Response>}
  #  */
  # async goBack(options) {
  #   return this._go(-1, options);
  # }

  # /**
  #  * @param {!{timeout?: number, waitUntil?: string|!Array<string>}=} options
  #  * @return {!Promise<?Puppeteer.Response>}
  #  */
  # async goForward(options) {
  #   return this._go(+1, options);
  # }

  # /**
  #  * @param {!{timeout?: number, waitUntil?: string|!Array<string>}=} options
  #  * @return {!Promise<?Puppeteer.Response>}
  #  */
  # async _go(delta, options) {
  #   const history = await this._client.send('Page.getNavigationHistory');
  #   const entry = history.entries[history.currentIndex + delta];
  #   if (!entry)
  #     return null;
  #   const [response] = await Promise.all([
  #     this.waitForNavigation(options),
  #     this._client.send('Page.navigateToHistoryEntry', {entryId: entry.id}),
  #   ]);
  #   return response;
  # }

  # async bringToFront() {
  #   await this._client.send('Page.bringToFront');
  # }

    # @param {!{viewport: !Puppeteer.Viewport, userAgent: string}} options
    #
    def emulate(user_agent:, viewport:)
      set_viewport viewport
      set_user_agent user_agent
    end

    # @param [Boolean] enabled
    #
    def set_javascript_enabled(enabled)
      return if javascript_enabled == enabled

      @javascript_enabled = enabled
      client.command Protocol::Emulation.set_script_execution_disabled value: !javascript_enabled
    end

  # /**
  #  * @param {boolean} enabled
  #  */
  # async setBypassCSP(enabled) {
  #   await this._client.send('Page.setBypassCSP', { enabled });
  # }

    # @param {?string} mediaType
    #
    def emulate_media(media_type = nil)
      raise "Unsupported media type: #{media_type}" unless ['screen', 'print', nil].include? media_type
      client.command Protocol::Emulation.set_emulated_media media: media_type || ''
    end

    # @param {!Puppeteer.Viewport} viewport
    #
    # # TODO move to keyword args from EmulationManager#emulate_viewport
    def set_viewport(viewport)
      needs_reload = @_emulation_manager.emulate_viewport viewport
      @_viewport = viewport

      reload if needs_reload
    end

    # @return {?Puppeteer.Viewport}
    #
    def viewport
      @_viewport
    end

    # TODO
    #  * @param {Function|string} pageFunction
    #  * @param {!Array<*>} args
    #  * @return {!Promise<*>}
    #
    def evaluate(function, *args)
      # TODO make remove calls to this where function: true is passed and
      # replace with calls to evaluate_function
      main_frame.evaluate function, *args
    end

    def evaluate_function(function, *args)
      main_frame.evaluate function, *args, function: true
    end

  # /**
  #  * @param {Function|string} pageFunction
  #  * @param {!Array<*>} args
  #  */
  # async evaluateOnNewDocument(pageFunction, ...args) {
  #   const source = helper.evaluationString(pageFunction, ...args);
  #   await this._client.send('Page.addScriptToEvaluateOnNewDocument', { source });
  # }

  # /**
  #  * @param {boolean} enabled
  #  */
  # async setCacheEnabled(enabled = true) {
  #   await this._frameManager.networkManager().setCacheEnabled(enabled);
  # }

  # /**
  #  * @param {!ScreenshotOptions=} options
  #  * @return {!Promise<!Buffer|!String>}
  #  */
  # async screenshot(options = {}) {
  #   let screenshotType = null;
  #   // options.type takes precedence over inferring the type from options.path
  #   // because it may be a 0-length file with no extension created beforehand (i.e. as a temp file).
  #   if (options.type) {
  #     assert(options.type === 'png' || options.type === 'jpeg', 'Unknown options.type value: ' + options.type);
  #     screenshotType = options.type;
  #   } else if (options.path) {
  #     const mimeType = mime.getType(options.path);
  #     if (mimeType === 'image/png')
  #       screenshotType = 'png';
  #     else if (mimeType === 'image/jpeg')
  #       screenshotType = 'jpeg';
  #     assert(screenshotType, 'Unsupported screenshot mime type: ' + mimeType);
  #   }

  #   if (!screenshotType)
  #     screenshotType = 'png';

  #   if (options.quality) {
  #     assert(screenshotType === 'jpeg', 'options.quality is unsupported for the ' + screenshotType + ' screenshots');
  #     assert(typeof options.quality === 'number', 'Expected options.quality to be a number but found ' + (typeof options.quality));
  #     assert(Number.isInteger(options.quality), 'Expected options.quality to be an integer');
  #     assert(options.quality >= 0 && options.quality <= 100, 'Expected options.quality to be between 0 and 100 (inclusive), got ' + options.quality);
  #   }
  #   assert(!options.clip || !options.fullPage, 'options.clip and options.fullPage are exclusive');
  #   if (options.clip) {
  #     assert(typeof options.clip.x === 'number', 'Expected options.clip.x to be a number but found ' + (typeof options.clip.x));
  #     assert(typeof options.clip.y === 'number', 'Expected options.clip.y to be a number but found ' + (typeof options.clip.y));
  #     assert(typeof options.clip.width === 'number', 'Expected options.clip.width to be a number but found ' + (typeof options.clip.width));
  #     assert(typeof options.clip.height === 'number', 'Expected options.clip.height to be a number but found ' + (typeof options.clip.height));
  #     assert(options.clip.width !== 0, 'Expected options.clip.width not to be 0.');
  #     assert(options.clip.height !== 0, 'Expected options.clip.width not to be 0.');
  #   }
  #   return this._screenshotTaskQueue.postTask(this._screenshotTask.bind(this, screenshotType, options));
  # }

  # /**
  #  * @param {"png"|"jpeg"} format
  #  * @param {!ScreenshotOptions=} options
  #  * @return {!Promise<!Buffer|!String>}
  #  */
  # async _screenshotTask(format, options) {
  #   await this._client.send('Target.activateTarget', {targetId: this._target._targetId});
  #   let clip = options.clip ? processClip(options.clip) : undefined;

  #   if (options.fullPage) {
  #     const metrics = await this._client.send('Page.getLayoutMetrics');
  #     const width = Math.ceil(metrics.contentSize.width);
  #     const height = Math.ceil(metrics.contentSize.height);

  #     // Overwrite clip for full page at all times.
  #     clip = { x: 0, y: 0, width, height, scale: 1 };
  #     const {
  #       isMobile = false,
  #       deviceScaleFactor = 1,
  #       isLandscape = false
  #     } = this._viewport || {};
  #     /** @type {!Protocol.Emulation.ScreenOrientation} */
  #     const screenOrientation = isLandscape ? { angle: 90, type: 'landscapePrimary' } : { angle: 0, type: 'portraitPrimary' };
  #     await this._client.send('Emulation.setDeviceMetricsOverride', { mobile: isMobile, width, height, deviceScaleFactor, screenOrientation });
  #   }
  #   const shouldSetDefaultBackground = options.omitBackground && format === 'png';
  #   if (shouldSetDefaultBackground)
  #     await this._client.send('Emulation.setDefaultBackgroundColorOverride', { color: { r: 0, g: 0, b: 0, a: 0 } });
  #   const result = await this._client.send('Page.captureScreenshot', { format, quality: options.quality, clip });
  #   if (shouldSetDefaultBackground)
  #     await this._client.send('Emulation.setDefaultBackgroundColorOverride');

  #   if (options.fullPage && this._viewport)
  #     await this.setViewport(this._viewport);

  #   const buffer = options.encoding === 'base64' ? result.data : Buffer.from(result.data, 'base64');
  #   if (options.path)
  #     await writeFileAsync(options.path, buffer);
  #   return buffer;

  #   function processClip(clip) {
  #     const x = Math.round(clip.x);
  #     const y = Math.round(clip.y);
  #     const width = Math.round(clip.width + clip.x - x);
  #     const height = Math.round(clip.height + clip.y - y);
  #     return {x, y, width, height, scale: 1};
  #   }
  # }

  # /**
  #  * @param {!PDFOptions=} options
  #  * @return {!Promise<!Buffer>}
  #  */
  # async pdf(options = {}) {
  #   const {
  #     scale = 1,
  #     displayHeaderFooter = false,
  #     headerTemplate = '',
  #     footerTemplate = '',
  #     printBackground = false,
  #     landscape = false,
  #     pageRanges = '',
  #     preferCSSPageSize = false,
  #     margin = {},
  #     path = null
  #   } = options;

  #   let paperWidth = 8.5;
  #   let paperHeight = 11;
  #   if (options.format) {
  #     const format = Page.PaperFormats[options.format.toLowerCase()];
  #     assert(format, 'Unknown paper format: ' + options.format);
  #     paperWidth = format.width;
  #     paperHeight = format.height;
  #   } else {
  #     paperWidth = convertPrintParameterToInches(options.width) || paperWidth;
  #     paperHeight = convertPrintParameterToInches(options.height) || paperHeight;
  #   }

  #   const marginTop = convertPrintParameterToInches(margin.top) || 0;
  #   const marginLeft = convertPrintParameterToInches(margin.left) || 0;
  #   const marginBottom = convertPrintParameterToInches(margin.bottom) || 0;
  #   const marginRight = convertPrintParameterToInches(margin.right) || 0;

  #   const result = await this._client.send('Page.printToPDF', {
  #     landscape,
  #     displayHeaderFooter,
  #     headerTemplate,
  #     footerTemplate,
  #     printBackground,
  #     scale,
  #     paperWidth,
  #     paperHeight,
  #     marginTop,
  #     marginBottom,
  #     marginLeft,
  #     marginRight,
  #     pageRanges,
  #     preferCSSPageSize
  #   });
  #   const buffer = Buffer.from(result.data, 'base64');
  #   if (path !== null)
  #     await writeFileAsync(path, buffer);
  #   return buffer;
  # }

    # Page Title
    #
    # @return [String]
    #
    def title
      main_frame.title
    end

    # TODO DOCUMENT
    def close(run_before_unload: false)
      #  assert(!!this._client._connection, 'Protocol error: Connection closed. Most likely the page has been closed.');
      if run_before_unload
        # await this._client.send('Page.close');
      else
        await client.client.command Protocol::Target.close_target target_id: target.target_id
        # await this._target._isClosedPromise;
      end
    end

  # /**
  #  * @return {boolean}
  #  */
  # isClosed() {
  #   return this._closed;
  # }

    # @param {string} selector
    # @param {!{delay?: number, button?: "left"|"right"|"middle", clickCount?: number}=} options
    #
    def click(selector, options = {})
      main_frame.click selector, options
    end

    # @param {string} selector
    #
    def focus(selector)
      main_frame.focus selector
    end

    # @param {string} selector
    #
    def hover(selector)
      main_frame.hover selector
    end

  # /**
  #  * @param {string} selector
  #  * @param {!Array<string>} values
  #  * @return {!Promise<!Array<string>>}
  #  */
  # select(selector, ...values) {
  #   return this.mainFrame().select(selector, ...values);
  # }

    #  @param [String] selector
    #
    def touchscreen_tap(selector)
      main_frame.touchscreen_tap selector
    end

    # @param {string} selector
    # @param {string} text
    # @param {{delay: (number|undefined)}=} options
    #
    def type(selector, text, delay: nil)
      main_frame.type selector, text, delay: delay
    end

  # /**
  #  * @param {(string|number|Function)} selectorOrFunctionOrTimeout
  #  * @param {!Object=} options
  #  * @param {!Array<*>} args
  #  * @return {!Promise<!Puppeteer.JSHandle>}
  #  */
  # waitFor(selectorOrFunctionOrTimeout, options = {}, ...args) {
  #   return this.mainFrame().waitFor(selectorOrFunctionOrTimeout, options, ...args);
  # }

  # /**
  #  * @param {string} selector
  #  * @param {!{visible?: boolean, hidden?: boolean, timeout?: number}=} options
  #  * @return {!Promise<?Puppeteer.ElementHandle>}
  #  */
  # waitForSelector(selector, options = {}) {
  #   return this.mainFrame().waitForSelector(selector, options);
  # }

  # /**
  #  * @param {string} xpath
  #  * @param {!{visible?: boolean, hidden?: boolean, timeout?: number}=} options
  #  * @return {!Promise<?Puppeteer.ElementHandle>}
  #  */
  # waitForXPath(xpath, options = {}) {
  #   return this.mainFrame().waitForXPath(xpath, options);
  # }

  # /**
  #  * @param {Function} pageFunction
  #  * @param {!{polling?: string|number, timeout?: number}=} options
  #  * @param {!Array<*>} args
  #  * @return {!Promise<!Puppeteer.JSHandle>}
  #  */
  # waitForFunction(pageFunction, options = {}, ...args) {
  #   return this.mainFrame().waitForFunction(pageFunction, options, ...args);
  # }

    private

      def client
        @client ||= target.session
      end

      # _onTargetCrashed() {
      #   this.emit('error', new Error('Page crashed!'));
      # }

      #  * @param {!Protocol.Log.entryAddedPayload} event
      #  */
      # _onLogEntryAdded(event) {
      #   const {level, text, args, source, url, lineNumber} = event.entry;
      #   if (args)
      #     args.map(arg => helper.releaseObject(this._client, arg));
      #   if (source !== 'worker')
      #     this.emit(Events.Page.Console, new ConsoleMessage(level, text, [], {url, lineNumber}));
      # }

      def on_dialog(event)
        dialog_type =
          case event["type"]
          when 'alert' then Dialog::ALERT
          when 'confirm' then Dialog::CONFIRM
          when 'prompt' then Dialog::PROMPT
          when 'beforeunload' then Dialog::BEFORE_UNLOAD
          else
            raise "Unknown javascript dialog type: #{event["type"]}"
          end
        dialog = Dialog.new client, dialog_type, event["message"], event["defaultPrompt"]

        emit :dialog, dialog
      end
  end
end
