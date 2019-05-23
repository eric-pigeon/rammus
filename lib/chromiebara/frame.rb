module Chromiebara
  class Frame
    attr_reader :id, :frame_manager, :child_frames, :loader_id, :main_world

    # @param [Chromiebara::FrameManager] frame_manager
    # @param [Chromiebara::CPDSession] client
    # @param [Chromiebara::Frame, nil] parent_frame
    # @param [Integer] id
    #
    def initialize(frame_manager, client, parent_frame, id)
      @frame_manager = frame_manager
      @client = client
      @parent_frame = parent_frame
      @_url = ''
      @id = id
      @_detached = false
      @name = ''

      @loader_id = ''
      # /** @type {!Set<string>} */
      @_lifecycle_events = Set.new
      # /** @type {!DOMWorld} */
      @main_world =  DOMWorld.new frame_manager, self#, frameManager._timeoutSettings
      # /** @type {!DOMWorld} */
      @_secondary_world = DOMWorld.new frame_manager, self#, frameManager._timeoutSettings);

      # /** @type {!Set<!Frame>} */
      @child_frames = Set.new
      if parent_frame
        parent_frame.child_frames.add self
      end
    end

    # TODO
    #
    def lifecycle_events
      @_lifecycle_events.dup
    end

    # @param [String] url
    # TODO
    #
    def goto(url, referrer: nil, timeout: nil, wait_until: nil)
      frame_manager.navigate_frame self, url, referrer: referrer, timeout: timeout, wait_until: wait_until
    end

  # /**
  #  * @param {!{timeout?: number, waitUntil?: string|!Array<string>}=} options
  #  * @return {!Promise<?Puppeteer.Response>}
  #  */
  # async waitForNavigation(options) {
  #   return await this._frameManager.waitForFrameNavigation(this, options);
  # }

  # /**
  #  * @return {!Promise<!ExecutionContext>}
  #  */
  # executionContext() {
  #   return this._mainWorld.executionContext();
  # }

  # /**
  #  * @param {Function|string} pageFunction
  #  * @param {!Array<*>} args
  #  * @return {!Promise<!Puppeteer.JSHandle>}
  #  */
  # async evaluateHandle(pageFunction, ...args) {
  #   return this._mainWorld.evaluateHandle(pageFunction, ...args);
  # }

    # TODO
    #  * @param {Function|string} pageFunction
    #  * @param {!Array<*>} args
    #  * @return {!Promise<*>}
    #
    def evaluate(function, *args)
      @main_world.evaluate function, *args
    end

  # /**
  #  * @param {string} selector
  #  * @return {!Promise<?Puppeteer.ElementHandle>}
  #  */
  # async $(selector) {
  #   return this._mainWorld.$(selector);
  # }

  # /**
  #  * @param {string} expression
  #  * @return {!Promise<!Array<!Puppeteer.ElementHandle>>}
  #  */
  # async $x(expression) {
  #   return this._mainWorld.$x(expression);
  # }

  # /**
  #  * @param {string} selector
  #  * @param {Function|string} pageFunction
  #  * @param {!Array<*>} args
  #  * @return {!Promise<(!Object|undefined)>}
  #  */
  # async $eval(selector, pageFunction, ...args) {
  #   return this._mainWorld.$eval(selector, pageFunction, ...args);
  # }

  # /**
  #  * @param {string} selector
  #  * @param {Function|string} pageFunction
  #  * @param {!Array<*>} args
  #  * @return {!Promise<(!Object|undefined)>}
  #  */
  # async $$eval(selector, pageFunction, ...args) {
  #   return this._mainWorld.$$eval(selector, pageFunction, ...args);
  # }

  # /**
  #  * @param {string} selector
  #  * @return {!Promise<!Array<!Puppeteer.ElementHandle>>}
  #  */
  # async $$(selector) {
  #   return this._mainWorld.$$(selector);
  # }

    #  @return {!Promise<String>}
    #
    def content
      return @_secondary_world.content
    end

    # @param {string} html
    # @param {!{timeout?: number, waitUntil?: string|!Array<string>}=} options
    #
    def set_content(html, timeout: nil, wait_until: nil)
      @_secondary_world.set_content html, timeout: timeout, wait_until: wait_until
    end

  # /**
  #  * @return {string}
  #  */
  # name() {
  #   return this._name || '';
  # }

    # Frame's URL
    #
    # @return [String]
    #
    def url
      @_url
    end

  # /**
  #  * @return {?Frame}
  #  */
  # parentFrame() {
  #   return this._parentFrame;
  # }

  # /**
  #  * @return {!Array.<!Frame>}
  #  */
  # childFrames() {
  #   return Array.from(this._childFrames);
  # }

  # /**
  #  * @return {boolean}
  #  */
  # isDetached() {
  #   return this._detached;
  # }

  # /**
  #  * @param {!{url?: string, path?: string, content?: string, type?: string}} options
  #  * @return {!Promise<!Puppeteer.ElementHandle>}
  #  */
  # async addScriptTag(options) {
  #   return this._mainWorld.addScriptTag(options);
  # }

  # /**
  #  * @param {!{url?: string, path?: string, content?: string}} options
  #  * @return {!Promise<!Puppeteer.ElementHandle>}
  #  */
  # async addStyleTag(options) {
  #   return this._mainWorld.addStyleTag(options);
  # }

    # @param {string} selector
    # @param {!{delay?: number, button?: "left"|"right"|"middle", clickCount?: number}=} options
    #
    def click(selector, options)
      @_secondary_world.click selector, options
    end

  # /**
  #  * @param {string} selector
  #  */
  # async focus(selector) {
  #   return this._secondaryWorld.focus(selector);
  # }

  # /**
  #  * @param {string} selector
  #  */
  # async hover(selector) {
  #   return this._secondaryWorld.hover(selector);
  # }

  # /**
  # * @param {string} selector
  # * @param {!Array<string>} values
  # * @return {!Promise<!Array<string>>}
  # */
  # select(selector, ...values){
  #   return this._secondaryWorld.select(selector, ...values);
  # }

  # /**
  #  * @param {string} selector
  #  */
  # async tap(selector) {
  #   return this._secondaryWorld.tap(selector);
  # }

  # /**
  #  * @param {string} selector
  #  * @param {string} text
  #  * @param {{delay: (number|undefined)}=} options
  #  */
  # async type(selector, text, options) {
  #   return this._mainWorld.type(selector, text, options);
  # }

  # /**
  #  * @param {(string|number|Function)} selectorOrFunctionOrTimeout
  #  * @param {!Object=} options
  #  * @param {!Array<*>} args
  #  * @return {!Promise<?Puppeteer.JSHandle>}
  #  */
  # waitFor(selectorOrFunctionOrTimeout, options = {}, ...args) {
  #   const xPathPattern = '//';

  #   if (helper.isString(selectorOrFunctionOrTimeout)) {
  #     const string = /** @type {string} */ (selectorOrFunctionOrTimeout);
  #     if (string.startsWith(xPathPattern))
  #       return this.waitForXPath(string, options);
  #     return this.waitForSelector(string, options);
  #   }
  #   if (helper.isNumber(selectorOrFunctionOrTimeout))
  #     return new Promise(fulfill => setTimeout(fulfill, /** @type {number} */ (selectorOrFunctionOrTimeout)));
  #   if (typeof selectorOrFunctionOrTimeout === 'function')
  #     return this.waitForFunction(selectorOrFunctionOrTimeout, options, ...args);
  #   return Promise.reject(new Error('Unsupported target type: ' + (typeof selectorOrFunctionOrTimeout)));
  # }

  # /**
  #  * @param {string} selector
  #  * @param {!{visible?: boolean, hidden?: boolean, timeout?: number}=} options
  #  * @return {!Promise<?Puppeteer.ElementHandle>}
  #  */
  # async waitForSelector(selector, options) {
  #   const handle = await this._secondaryWorld.waitForSelector(selector, options);
  #   if (!handle)
  #     return null;
  #   const mainExecutionContext = await this._mainWorld.executionContext();
  #   const result = await mainExecutionContext._adoptElementHandle(handle);
  #   await handle.dispose();
  #   return result;
  # }

  # /**
  #  * @param {string} xpath
  #  * @param {!{visible?: boolean, hidden?: boolean, timeout?: number}=} options
  #  * @return {!Promise<?Puppeteer.ElementHandle>}
  #  */
  # async waitForXPath(xpath, options) {
  #   const handle = await this._secondaryWorld.waitForXPath(xpath, options);
  #   if (!handle)
  #     return null;
  #   const mainExecutionContext = await this._mainWorld.executionContext();
  #   const result = await mainExecutionContext._adoptElementHandle(handle);
  #   await handle.dispose();
  #   return result;
  # }

  # /**
  #  * @param {Function|string} pageFunction
  #  * @param {!{polling?: string|number, timeout?: number}=} options
  #  * @return {!Promise<!Puppeteer.JSHandle>}
  #  */
  # waitForFunction(pageFunction, options = {}, ...args) {
  #   return this._mainWorld.waitForFunction(pageFunction, options, ...args);
  # }

  # /**
  #  * @return {!Promise<string>}
  #  */
  # async title() {
  #   return this._secondaryWorld.title();
  # }

  private

    # @param [Hash] frame_payload Protocol.Page.Frame
    #
    def navigated(frame_payload)
      @name = frame_payload["name"]
      # TODO(lushnikov): remove this once requestInterception has loaderId exposed.
      # this._navigationURL = framePayload.url;
      @_url = frame_payload["url"]
    end

  # /**
  #  * @param {string} url
  #  */
  # _navigatedWithinDocument(url) {
  #   this._url = url;
  # }

    # @param [String] loader_id
    # @param [String] name
    #
    def on_lifecycle_event(loader_id, name)
      if name == "init"
        @loader_id = loader_id
        @_lifecycle_events.clear
      end

      @_lifecycle_events.add name
    end

    def on_loading_stopped
      @_lifecycle_events.add 'DOMContentLoaded'
      @_lifecycle_events.add 'load'
    end

  # _detach() {
  #   this._detached = true;
  #   this._mainWorld._detach();
  #   this._secondaryWorld._detach();
  #   if (this._parentFrame)
  #     this._parentFrame._childFrames.delete(this);
  #   this._parentFrame = null;
  # }
  end
end
