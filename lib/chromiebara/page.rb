module Chromiebara
  class Page
    extend Forwardable

    attr_reader :target, :frame_manager
    delegate [:url] => :main_frame

    def self.create(target)
      page = new target
      page.frame_manager.start
      target.session.command Protocol::Target.set_auto_attach auto_attach: true, wait_for_debugger_on_start: false, flatten: true
      # TODO add back
      # target.session.command Protocol::Performance.enable
      # target.session.command Protocol::Log.enable
      # if (defaultViewport)
        # await page.setViewport(defaultViewport);
      page
    end

    private_class_method :new
    def initialize(target)
      @_closed = false
      # this._client = client;
      @target = target
      # this._keyboard = new Keyboard(client);
      # this._mouse = new Mouse(client, this._keyboard);
      # this._timeoutSettings = new TimeoutSettings();
      # this._touchscreen = new Touchscreen(client, this._keyboard);
      # this._accessibility = new Accessibility(client);
      @frame_manager = FrameManager.new(client, self)
      # this._frameManager = new FrameManager(client, this, ignoreHTTPSErrors, this._timeoutSettings);
      # this._emulationManager = new EmulationManager(client);
      # this._tracing = new Tracing(client);
      # /** @type {!Map<string, Function>} */
      # this._pageBindings = new Map();
      # this._coverage = new Coverage(client);
      # this._javascriptEnabled = true;
      # /** @type {?Puppeteer.Viewport} */
      # this._viewport = null;

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
      # client.on('Page.javascriptDialogOpening', event => this._onDialog(event));
      # client.on('Runtime.exceptionThrown', exception => this._handleException(exception.exceptionDetails));
      # client.on('Inspector.targetCrashed', event => this._onTargetCrashed());
      # client.on('Performance.metrics', event => this._emitMetrics(event));
      # client.on('Log.entryAdded', event => this._onLogEntryAdded(event));
      # this._target._isClosedPromise.then(() => {
      #   this.emit(Events.Page.Close);
      #   this._closed = true;
      # });
    end

  # /**
  #  * @return {!Puppeteer.Target}
  #  */
  # target() {
  #   return this._target;
  # }

  # /**
  #  * @return {!Puppeteer.Browser}
  #  */
  # browser() {
  #   return this._target.browser();
  # }

  # /**
  #  * @return {!Puppeteer.BrowserContext}
  #  */
  # browserContext() {
  #   return this._target.browserContext();
  # }

  # _onTargetCrashed() {
  #   this.emit('error', new Error('Page crashed!'));
  # }

  # /**
  #  * @param {!Protocol.Log.entryAddedPayload} event
  #  */
  # _onLogEntryAdded(event) {
  #   const {level, text, args, source, url, lineNumber} = event.entry;
  #   if (args)
  #     args.map(arg => helper.releaseObject(this._client, arg));
  #   if (source !== 'worker')
  #     this.emit(Events.Page.Console, new ConsoleMessage(level, text, [], {url, lineNumber}));
  # }

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
  #  * @return {!Puppeteer.BrowserContext}
  #  */
  # browserContext() {

  # /**
  #  * @return {!Keyboard}
  #  */
  # get keyboard() {
  #   return this._keyboard;
  # }

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

  # /**
  #  * @return {!Accessibility}
  #  */
  # get accessibility() {
  #   return this._accessibility;
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

  # /**
  #  * @param {string} selector
  #  * @return {!Promise<?Puppeteer.ElementHandle>}
  #  */
  # async $(selector) {
  #   return this.mainFrame().$(selector);
  # }

  # /**
  #  * @param {Function|string} pageFunction
  #  * @param {!Array<*>} args
  #  * @return {!Promise<!Puppeteer.JSHandle>}
  #  */
  # async evaluateHandle(pageFunction, ...args) {
  #   const context = await this.mainFrame().executionContext();
  #   return context.evaluateHandle(pageFunction, ...args);
  # }

  # /**
  #  * @param {!Puppeteer.JSHandle} prototypeHandle
  #  * @return {!Promise<!Puppeteer.JSHandle>}
  #  */
  # async queryObjects(prototypeHandle) {
  #   const context = await this.mainFrame().executionContext();
  #   return context.queryObjects(prototypeHandle);
  # }

  # /**
  #  * @param {string} selector
  #  * @param {Function|string} pageFunction
  #  * @param {!Array<*>} args
  #  * @return {!Promise<(!Object|undefined)>}
  #  */
  # async $eval(selector, pageFunction, ...args) {
  #   return this.mainFrame().$eval(selector, pageFunction, ...args);
  # }

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

  # /**
  #  * @param {!Array<string>} urls
  #  * @return {!Promise<!Array<Network.Cookie>>}
  #  */
  # async cookies(...urls) {
  #   return (await this._client.send('Network.getCookies', {
  #     urls: urls.length ? urls : [this.url()]
  #   })).cookies;
  # }

  # /**
  #  * @param {Array<Protocol.Network.deleteCookiesParameters>} cookies
  #  */
  # async deleteCookie(...cookies) {
  #   const pageURL = this.url();
  #   for (const cookie of cookies) {
  #     const item = Object.assign({}, cookie);
  #     if (!cookie.url && pageURL.startsWith('http'))
  #       item.url = pageURL;
  #     await this._client.send('Network.deleteCookies', item);
  #   }
  # }

  # /**
  #  * @param {Array<Network.CookieParam>} cookies
  #  */
  # async setCookie(...cookies) {
  #   const pageURL = this.url();
  #   const startsWithHTTP = pageURL.startsWith('http');
  #   const items = cookies.map(cookie => {
  #     const item = Object.assign({}, cookie);
  #     if (!item.url && startsWithHTTP)
  #       item.url = pageURL;
  #     assert(item.url !== 'about:blank', `Blank page can not have cookie "${item.name}"`);
  #     assert(!String.prototype.startsWith.call(item.url || '', 'data:'), `Data URL page can not have cookie "${item.name}"`);
  #     return item;
  #   });
  #   await this.deleteCookie(...items);
  #   if (items.length)
  #     await this._client.send('Network.setCookies', { cookies: items });
  # }

  # /**
  #  * @param {!{url?: string, path?: string, content?: string, type?: string}} options
  #  * @return {!Promise<!Puppeteer.ElementHandle>}
  #  */
  # async addScriptTag(options) {
  #   return this.mainFrame().addScriptTag(options);
  # }

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

  # /**
  #  * @param {string} userAgent
  #  */
  # async setUserAgent(userAgent) {
  #   return this._frameManager.networkManager().setUserAgent(userAgent);
  # }

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

  # _onDialog(event) {
  #   let dialogType = null;
  #   if (event.type === 'alert')
  #     dialogType = Dialog.Type.Alert;
  #   else if (event.type === 'confirm')
  #     dialogType = Dialog.Type.Confirm;
  #   else if (event.type === 'prompt')
  #     dialogType = Dialog.Type.Prompt;
  #   else if (event.type === 'beforeunload')
  #     dialogType = Dialog.Type.BeforeUnload;
  #   assert(dialogType, 'Unknown javascript dialog type: ' + event.type);
  #   const dialog = new Dialog(this._client, dialogType, event.message, event.defaultPrompt);
  #   this.emit(Events.Page.Dialog, dialog);
  # }

  # /**
  #  * @return {!string}
  #  */
  # url() {
  #   return this.mainFrame().url();
  # }

  # /**
  #  * @return {!Promise<string>}
  #  */
  # async content() {
  #   return await this._frameManager.mainFrame().content();
  # }

  # /**
  #  * @param {string} html
  #  * @param {!{timeout?: number, waitUntil?: string|!Array<string>}=} options
  #  */
  # async setContent(html, options) {
  #   await this._frameManager.mainFrame().setContent(html, options);
  # }

    # @param [String] url
    # TODO
    #
    def goto(url, referrer: nil, timeout: nil, wait_until: nil)
      main_frame.goto url, referrer: referrer, timeout: timeout, wait_until: wait_until
    end

  # /**
  #  * @param {!{timeout?: number, waitUntil?: string|!Array<string>}=} options
  #  * @return {!Promise<?Puppeteer.Response>}
  #  */
  # async reload(options) {
  #   const [response] = await Promise.all([
  #     this.waitForNavigation(options),
  #     this._client.send('Page.reload')
  #   ]);
  #   return response;
  # }

  # /**
  #  * @param {!{timeout?: number, waitUntil?: string|!Array<string>}=} options
  #  * @return {!Promise<?Puppeteer.Response>}
  #  */
  # async waitForNavigation(options = {}) {
  #   return await this._frameManager.mainFrame().waitForNavigation(options);
  # }

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

  # /**
  #  * @param {!{viewport: !Puppeteer.Viewport, userAgent: string}} options
  #  */
  # async emulate(options) {
  #   await Promise.all([
  #     this.setViewport(options.viewport),
  #     this.setUserAgent(options.userAgent)
  #   ]);
  # }

  # /**
  #  * @param {boolean} enabled
  #  */
  # async setJavaScriptEnabled(enabled) {
  #   if (this._javascriptEnabled === enabled)
  #     return;
  #   this._javascriptEnabled = enabled;
  #   await this._client.send('Emulation.setScriptExecutionDisabled', { value: !enabled });
  # }

  # /**
  #  * @param {boolean} enabled
  #  */
  # async setBypassCSP(enabled) {
  #   await this._client.send('Page.setBypassCSP', { enabled });
  # }

  # /**
  #  * @param {?string} mediaType
  #  */
  # async emulateMedia(mediaType) {
  #   assert(mediaType === 'screen' || mediaType === 'print' || mediaType === null, 'Unsupported media type: ' + mediaType);
  #   await this._client.send('Emulation.setEmulatedMedia', {media: mediaType || ''});
  # }

  # /**
  #  * @param {!Puppeteer.Viewport} viewport
  #  */
  # async setViewport(viewport) {
  #   const needsReload = await this._emulationManager.emulateViewport(viewport);
  #   this._viewport = viewport;
  #   if (needsReload)
  #     await this.reload();
  # }

  # /**
  #  * @return {?Puppeteer.Viewport}
  #  */
  # viewport() {
  #   return this._viewport;
  # }

  # /**
  #  * @param {Function|string} pageFunction
  #  * @param {!Array<*>} args
  #  * @return {!Promise<*>}
  #  */
  # async evaluate(pageFunction, ...args) {
  #   return this._frameManager.mainFrame().evaluate(pageFunction, ...args);
  # }

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

    # TODO
    def close(run_before_unload: false)
      #  assert(!!this._client._connection, 'Protocol error: Connection closed. Most likely the page has been closed.');
      if run_before_unload
        # await this._client.send('Page.close');
      else
        client.client.command Protocol::Target.close_target target_id: target.target_id
        # await this._target._isClosedPromise;
      end
    end

  # /**
  #  * @return {boolean}
  #  */
  # isClosed() {
  #   return this._closed;
  # }

  # /**
  #  * @return {!Mouse}
  #  */
  # get mouse() {
  #   return this._mouse;
  # }

  # /**
  #  * @param {string} selector
  #  * @param {!{delay?: number, button?: "left"|"right"|"middle", clickCount?: number}=} options
  #  */
  # click(selector, options = {}) {
  #   return this.mainFrame().click(selector, options);
  # }

  # /**
  #  * @param {string} selector
  #  */
  # focus(selector) {
  #   return this.mainFrame().focus(selector);
  # }

  # /**
  #  * @param {string} selector
  #  */
  # hover(selector) {
  #   return this.mainFrame().hover(selector);
  # }

  # /**
  #  * @param {string} selector
  #  * @param {!Array<string>} values
  #  * @return {!Promise<!Array<string>>}
  #  */
  # select(selector, ...values) {
  #   return this.mainFrame().select(selector, ...values);
  # }

  # /**
  #  * @param {string} selector
  #  */
  # tap(selector) {
  #   return this.mainFrame().tap(selector);
  # }

  # /**
  #  * @param {string} selector
  #  * @param {string} text
  #  * @param {{delay: (number|undefined)}=} options
  #  */
  # type(selector, text, options) {
  #   return this.mainFrame().type(selector, text, options);
  # }

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
  end
end
