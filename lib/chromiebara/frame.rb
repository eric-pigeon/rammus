module Chromiebara
  class Frame
    extend Forwardable
    include Promise::Await

    delegate [:add_script_tag, :add_style_tag] => :main_world

    attr_reader :id, :frame_manager, :parent_frame, :loader_id, :main_world, :name

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
      @_name = nil

      @loader_id = ''
      # /** @type {!Set<string>} */
      @_lifecycle_events = Set.new
      # /** @type {!DOMWorld} */
      @main_world =  DOMWorld.new frame_manager, self, frame_manager.timeout_settings
      # /** @type {!DOMWorld} */
      @_secondary_world = DOMWorld.new frame_manager, self, frame_manager.timeout_settings

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
    def goto(url, referer: nil, timeout: nil, wait_until: nil)
      frame_manager.navigate_frame self, url, referer: referer, timeout: timeout, wait_until: wait_until
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

    def name
      @_name || ''
    end

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

    # @return {boolean}
    #
    def is_detached?
      @_detached
    end

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

    # @param {string} selector
    # @param {!Array<string>} values
    # @return {!Promise<!Array<string>>}
    #
    def select(selector, *values)
      secondary_world.select selector, *values
    end

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

    # @param {string} xpath
    # @param {!{visible?: boolean, hidden?: boolean, timeout?: number}=} options
    # @return {!Promise<?Puppeteer.ElementHandle>}
    #
    def wait_for_xpath(xpath, visible: nil, hidden: nil, timeout: nil)
      #handle = await secondary_world.wait_for_xpath xpath, visible: visible, hidden: hidden, timeout: timeout
      #return if handle.nil?
      #result = main_world.execution_context._adopt_element_handle handle
      #handle.dispose
      #result
      secondary_world.wait_for_xpath(xpath, visible: visible, hidden: hidden, timeout: timeout).then do |handle|
        next if handle.nil?
        result = main_world.execution_context._adopt_element_handle handle
        handle.dispose
        result
      end
    end

    # @param {Function|string} pageFunction
    # @param {!{polling?: string|number, timeout?: number}=} options
    # @return {!Promise<!Puppeteer.JSHandle>}
    #
    def wait_for_function(page_function, *args, polling: nil, timeout: nil)
      main_world.wait_for_function page_function, *args, polling: polling, timeout: timeout
    end

    def title
      secondary_world.title
    end

    def _detach
      @_detached = true
      main_world._detach
      secondary_world._detach
      # TODO
      parent_frame.instance_variable_get(:@child_frames).delete self if parent_frame
      @parent_frame = nil
    end

    # @param {string} url
    #
    def _navigated_within_document(url)
      @_url = url
    end

    private

      # @param [Hash] frame_payload Protocol.Page.Frame
      #
      def navigated(frame_payload)
        @_name = frame_payload["name"]
        @_url = frame_payload["url"]
      end

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
  end
end
