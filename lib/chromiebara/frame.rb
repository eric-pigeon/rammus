module Chromiebara
  class Frame
    attr_reader :id, :frame_manager, :parent_frame, :loader_id, :main_world

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
        # TODO
        parent_frame.instance_variable_get(:@child_frames).add self
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

    # @param {!{timeout?: number, waitUntil?: string|!Array<string>}=} options
    # @return {!Promise<?Puppeteer.Response>}
    #
    def wait_for_navigation(timeout: nil, wait_until: nil)
      frame_manager.wait_for_frame_navigation self, timeout: timeout, wait_until: wait_until
    end

    # @return {!Promise<!ExecutionContext>}
    #
    def execution_context
      main_world.execution_context
    end

    # @param {Function|string} pageFunction
    # @param {!Array<*>} args
    # @return {!Promise<!Puppeteer.JSHandle>}
    #
    def evaluate_handle(page_function, *args)
      main_world.evaluate_handle page_function, *args
    end

    # TODO
    def evaluate_handle_function(page_function, *args)
      main_world.evaluate_handle_function page_function, *args
    end

    # TODO
    #  * @param {Function|string} pageFunction
    #  * @param {!Array<*>} args
    #  * @return {!Promise<*>}
    #
    def evaluate(function, *args)
      @main_world.evaluate function, *args
    end

    def evaluate_function(function, *args)
      main_world.evaluate_function function, *args
    end

    # @param {string} selector
    # @return {!Promise<?Puppeteer.ElementHandle>}
    #
    def query_selector(selector)
      main_world.query_selector selector
    end

    # @param {string} expression
    # @return {!Promise<!Array<!Puppeteer.ElementHandle>>}
    #
    def xpath(expression)
      main_world.xpath expression
    end

    # @param {string} selector
    # @param {Function|string} pageFunction
    # @param {!Array<*>} args
    # @return {!Promise<(!Object|undefined)>}
    #
    def query_selector_evaluate_function(selector, function, *args)
      main_world.query_selector_evaluate_function selector, function, *args
    end

    # @param {string} selector
    # @param {Function|string} pageFunction
    # @param {!Array<*>} args
    # @return {!Promise<(!Object|undefined)>}
    #
    def query_selector_all_evaluate_function(selector, page_function, *args)
      main_world.query_selector_all_evaluate_function selector, page_function, *args
    end

    # @param {string} selector
    # @return {!Promise<!Array<!Puppeteer.ElementHandle>>}
    #
    def query_selector_all(selector)
       main_world.query_selector_all selector
    end

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

    # @return {!Array.<!Frame>}
    #
    def child_frames
      @child_frames.to_a
    end

    #  * @return {boolean}
    #  */
    # isDetached() {
    #   return this._detached;
    # }

    #  * @param {!{url?: string, path?: string, content?: string, type?: string}} options
    #  * @return {!Promise<!Puppeteer.ElementHandle>}
    #  */
    def add_script_tag(url: nil, path: nil, content: nil, type: nil)
      main_world.add_script_tag url: url, path: path, content: content, type: type
    end

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

    # TODO make attr_reader
    def secondary_world
      @_secondary_world
    end

    # @param {string} selector
    #
    def focus(selector)
      secondary_world.focus selector
    end

    # @param {string} selector
    #
    def hover(selector)
      secondary_world.hover selector
    end

    # * @param {string} selector
    # * @param {!Array<string>} values
    # * @return {!Promise<!Array<string>>}
    # */
    # select(selector, ...values){
    #   return this._secondaryWorld.select(selector, ...values);
    # }

    # @param [String] selector
    #
    def touchscreen_tap(selector)
      secondary_world.touchscreen_tap selector
    end

    # @param {string} selector
    # @param {string} text
    # @param {{delay: (number|undefined)}=} options
    #
    def type(selector, text, delay: nil)
      main_world.type selector, text, delay: delay
    end

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

    #  * @return {!Promise<string>}
    #  */
    def title
      secondary_world.title
    end

    private

      # @param [Hash] frame_payload Protocol.Page.Frame
      #
      def navigated(frame_payload)
        @name = frame_payload["name"]
        # TODO(lushnikov): remove this once requestInterception has loaderId exposed.
        # this._navigationURL = framePayload.url;
        @_url = frame_payload["url"]
      end

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
