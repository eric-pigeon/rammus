module Chromiebara
  class DOMWorld
    include Promise::Await

    attr_reader :frame_manager, :frame

    # @param [Chromiebara::FrameManager] frame_manager
    # @param [Chromiebara::Frame] frame
    #* @param {!Puppeteer.TimeoutSettings} timeoutSettings
    #
    def initialize(frame_manager, frame)
      @frame_manager = frame_manager
      @frame = frame
      # this._timeoutSettings = timeoutSettings;

      # /** @type {?Promise<!Puppeteer.ElementHandle>} */
      # this._documentPromise = null;
      # /** @type {!Promise<!Puppeteer.ExecutionContext>} */
      @_context_promise = nil
      # this._contextPromise;
      # this._contextResolveCallback = null;
      @_context_resolve_callback = nil
      set_context nil
      #
      # /** @type {!Set<!WaitTask>} */
      # this._waitTasks = new Set();
      @_detached = false
      # @context = nil
    end

    #  * @return {boolean}
    #  */
    def has_context?
      @_context_resolve_callback.nil?
    end

    # @return {!Promise<!Puppeteer.ExecutionContext>}
    #
    def execution_context
      raise "Execution Context is not available in detached frame \"#{frame.url}\" (are you trying to evaluate?)" if @_detached
      await @_context_promise
    end

    # @param {Function|string} pageFunction
    # @param {!Array<*>} args
    # @return {!Promise<!Puppeteer.JSHandle>}
    #
    def evaluate_handle(page_function, *args)
      execution_context.evaluate_handle page_function, *args
    end

    # * @param {Function|string} pageFunction
    # * @param {!Array<*>} args
    # * @return {!Promise<*>}
    #
    def evaluate(function, *args)
      execution_context.evaluate function, *args
    end

    def evaluate_function(function, *args)
      execution_context.evaluate_function function, *args
    end

    # TODO
    def evaluate_handle_function(function, *args)
      execution_context.evaluate_handle_function function, *args
    end

    # @param {string} selector
    # @return {!Promise<?Puppeteer.ElementHandle>}
    #
    def query_selector(selector)
      document.query_selector selector
    end

    # @return {!Promise<!Puppeteer.ElementHandle>}
    #
    def document
      execution_context.evaluate_handle('document').as_element
      # if (this._documentPromise)
      #   return this._documentPromise;
      # this._documentPromise = this.executionContext().then(async context => {
      #   const document = await context.evaluateHandle('document');
      #   return document.asElement();
      # });
      # return this._documentPromise;
    end

    # @param {string} expression
    # @return {!Promise<!Array<!Puppeteer.ElementHandle>>}
    #
    def xpath(expression)
      document.xpath expression
    end

    # @param {string} selector
    # @param {Function|string} pageFunction
    # @param {!Array<*>} args
    # @return {!Promise<(!Object|undefined)>}
    #
    def query_selector_evaluate_function(selector, page_function, *args)
      document.query_selector_evaluate_function selector, page_function, *args
    end

    #  @param {string} selector
    #  @param {Function|string} pageFunction
    #  @param {!Array<*>} args
    #  @return {!Promise<(!Object|undefined)>}
    #
    def query_selector_all_evaluate_function(selector, page_function, *args)
      document.query_selector_all_evaluate_function selector, page_function, *args
    end

    # @param {string} selector
    # @return {!Promise<!Array<!Puppeteer.ElementHandle>>}
    #
    def query_selector_all(selector)
      document.query_selector_all selector
    end

    # * @return {!Promise<String>}
    #
    def content
      function = <<~JAVASCRIPT
      () => {
        let retVal = '';
        if (document.doctype)
          retVal = new XMLSerializer().serializeToString(document.doctype);
        if (document.documentElement)
          retVal += document.documentElement.outerHTML;
        return retVal;
      }
      JAVASCRIPT
      evaluate_function function
    end

    #  * @param {string} html
    #  * @param {!{timeout?: number, waitUntil?: string|!Array<string>}=} options
    #  */
    def set_content(html, timeout: nil, wait_until: nil)
      wait_until = [:load]
      # timeout = this._timeoutSettings.navigationTimeout(),
      # We rely upon the fact that document.open() will reset frame lifecycle with "init"
      # lifecycle event. @see https://crrev.com/608658

      watcher = LifecycleWatcher.new frame_manager, frame, wait_until, timeout
      function = <<~JAVASCRIPT
      html => {
        document.open();
        document.write(html);
        document.close();
      }
      JAVASCRIPT
      evaluate_function function, html
      watcher.await_complete
    ensure
      watcher.dispose
      # const watcher = new LifecycleWatcher(this._frameManager, this._frame, waitUntil, timeout);
      # const error = await Promise.race([
      #   watcher.timeoutOrTerminationPromise(),
      #   watcher.lifecyclePromise(),
      # ]);
      # watcher.dispose();
      # if (error)
      #   throw error;

    end

    # @param {!{url?: string, path?: string, content?: string, type?: string}} options
    # @return {!Promise<!Puppeteer.ElementHandle>}
    #
    def add_script_tag(url: nil, path: nil, content: nil, type: '')

      #/**
      # * @param {string} url
      # * @param {string} type
      # * @return {!Promise<!HTMLElement>}
      # */
      add_script_url = <<~JAVASCRIPT
      async function addScriptUrl(url, type) {
        const script = document.createElement('script');
        script.src = url;
        if (type)
          script.type = type;
        const promise = new Promise((res, rej) => {
          script.onload = res;
          script.onerror = rej;
        });
        document.head.appendChild(script);
        await promise;
        return script;
      }
      JAVASCRIPT

      if url != nil
        begin
          execution_context.evaluate_handle_function(add_script_url, url, type).as_element
        rescue => _error
          raise "Loading script from #{url} failed"
        end
      end

      #if (path !== null) {
      #  let contents = await readFileAsync(path, 'utf8');
      #  contents += '//# sourceURL=' + path.replace(/\n/g, '');
      #  const context = await this.executionContext();
      #  return (await context.evaluateHandle(addScriptContent, contents, type)).asElement();
      #}

      #if (content !== null) {
      #  const context = await this.executionContext();
      #  return (await context.evaluateHandle(addScriptContent, content, type)).asElement();
      #}

      #throw new Error('Provide an object with a `url`, `path` or `content` property');

      #/**
      # * @param {string} content
      # * @param {string} type
      # * @return {!HTMLElement}
      # */
      #function addScriptContent(content, type = 'text/javascript') {
      #  const script = document.createElement('script');
      #  script.type = type;
      #  script.text = content;
      #  let error = null;
      #  script.onerror = e => error = e;
      #  document.head.appendChild(script);
      #  if (error)
      #    throw error;
      #  return script;
      #}
    end

    #  * @param {!{url?: string, path?: string, content?: string}} options
    #  * @return {!Promise<!Puppeteer.ElementHandle>}
    #  */
    # async addStyleTag(options) {
    #   const {
    #     url = null,
    #     path = null,
    #     content = null
    #   } = options;
    #   if (url !== null) {
    #     try {
    #       const context = await this.executionContext();
    #       return (await context.evaluateHandle(addStyleUrl, url)).asElement();
    #     } catch (error) {
    #       throw new Error(`Loading style from ${url} failed`);
    #     }
    #   }

    #   if (path !== null) {
    #     let contents = await readFileAsync(path, 'utf8');
    #     contents += '/*# sourceURL=' + path.replace(/\n/g, '') + '*/';
    #     const context = await this.executionContext();
    #     return (await context.evaluateHandle(addStyleContent, contents)).asElement();
    #   }

    #   if (content !== null) {
    #     const context = await this.executionContext();
    #     return (await context.evaluateHandle(addStyleContent, content)).asElement();
    #   }

    #   throw new Error('Provide an object with a `url`, `path` or `content` property');

    #   /**
    #    * @param {string} url
    #    * @return {!Promise<!HTMLElement>}
    #    */
    #   async function addStyleUrl(url) {
    #     const link = document.createElement('link');
    #     link.rel = 'stylesheet';
    #     link.href = url;
    #     const promise = new Promise((res, rej) => {
    #       link.onload = res;
    #       link.onerror = rej;
    #     });
    #     document.head.appendChild(link);
    #     await promise;
    #     return link;
    #   }

    #   /**
    #    * @param {string} content
    #    * @return {!Promise<!HTMLElement>}
    #    */
    #   async function addStyleContent(content) {
    #     const style = document.createElement('style');
    #     style.type = 'text/css';
    #     style.appendChild(document.createTextNode(content));
    #     const promise = new Promise((res, rej) => {
    #       style.onload = res;
    #       style.onerror = rej;
    #     });
    #     document.head.appendChild(style);
    #     await promise;
    #     return style;
    #   }
    # }

    # @param {string} selector
    # @param {!{delay?: number, button?: "left"|"right"|"middle", clickCount?: number}=} options
    #
    def click(selector, options)
      handle = query_selector selector
      raise "No node found for selector: #{selector}" if handle.nil?
      handle.click options
      handle.dispose
    end

    # @param {string} selector
    #
    def focus(selector)
      handle = query_selector selector
      "No node found for selector: #{selector}" if handle.nil?
      handle.focus
      handle.dispose
    end

    # @param {string} selector
    #
    def hover(selector)
      handle = query_selector selector
      raise "No node found for selector: #{selector}" if handle.nil?
      handle.hover
      handle.dispose
    end

    # * @param {string} selector
    # * @param {!Array<string>} values
    # * @return {!Promise<!Array<string>>}
    # */
    # select(selector, ...values){
    #   for (const value of values)
    #     assert(helper.isString(value), 'Values must be strings. Found value "' + value + '" of type "' + (typeof value) + '"');
    #   return this.$eval(selector, (element, values) => {
    #     if (element.nodeName.toLowerCase() !== 'select')
    #       throw new Error('Element is not a <select> element.');

    #     const options = Array.from(element.options);
    #     element.value = undefined;
    #     for (const option of options) {
    #       option.selected = values.includes(option.value);
    #       if (option.selected && !element.multiple)
    #         break;
    #     }
    #     element.dispatchEvent(new Event('input', { 'bubbles': true }));
    #     element.dispatchEvent(new Event('change', { 'bubbles': true }));
    #     return options.filter(option => option.selected).map(option => option.value);
    #   }, values);
    # }

    # @param [String] selector
    #
    def touchscreen_tap(selector)
      handle = query_selector selector
      raise "No node found for selector: #{selector}" if handle.nil?
      handle.tap
      handle.dispose
    end

    # @param {string} selector
    # @param {string} text
    # @param {{delay: (number|undefined)}=} options
    #
    def type(selector, text, delay: nil)
      handle = query_selector selector
      raise "No node found for selector: #{selector}" if handle.nil?
      handle.type text, delay: delay
      handle.dispose
    end

    # TODO
    #  * @param {string} selector
    #  * @param {!{visible?: boolean, hidden?: boolean, timeout?: number}=} options
    #  * @return {!Promise<?Puppeteer.ElementHandle>}
    #  */
    # waitForSelector(selector, options) {
    #   return this._waitForSelectorOrXPath(selector, false, options);
    # }

    #  * @param {string} xpath
    #  * @param {!{visible?: boolean, hidden?: boolean, timeout?: number}=} options
    #  * @return {!Promise<?Puppeteer.ElementHandle>}
    #  */
    # waitForXPath(xpath, options) {
    #   return this._waitForSelectorOrXPath(xpath, true, options);
    # }

    #  * @param {Function|string} pageFunction
    #  * @param {!{polling?: string|number, timeout?: number}=} options
    #  * @return {!Promise<!Puppeteer.JSHandle>}
    #  */
    # waitForFunction(pageFunction, options = {}, ...args) {
    #   const {
    #     polling = 'raf',
    #     timeout = this._timeoutSettings.timeout(),
    #   } = options;
    #   return new WaitTask(this, pageFunction, 'function', polling, timeout, ...args).promise;
    # }

    #  * @return {!Promise<string>}
    #  */
    def title
      evaluate('document.title')
    end

    # TODO
    #  * @param {string} selectorOrXPath
    #  * @param {boolean} isXPath
    #  * @param {!{visible?: boolean, hidden?: boolean, timeout?: number}=} options
    #  * @return {!Promise<?Puppeteer.ElementHandle>}
    #  */
    # async _waitForSelectorOrXPath(selectorOrXPath, isXPath, options = {}) {
    #   const {
    #     visible: waitForVisible = false,
    #     hidden: waitForHidden = false,
    #     timeout = this._timeoutSettings.timeout(),
    #   } = options;
    #   const polling = waitForVisible || waitForHidden ? 'raf' : 'mutation';
    #   const title = `${isXPath ? 'XPath' : 'selector'} "${selectorOrXPath}"${waitForHidden ? ' to be hidden' : ''}`;
    #   const waitTask = new WaitTask(this, predicate, title, polling, timeout, selectorOrXPath, isXPath, waitForVisible, waitForHidden);
    #   const handle = await waitTask.promise;
    #   if (!handle.asElement()) {
    #     await handle.dispose();
    #     return null;
    #   }
    #   return handle.asElement();

    #    * @param {string} selectorOrXPath
    #    * @param {boolean} isXPath
    #    * @param {boolean} waitForVisible
    #    * @param {boolean} waitForHidden
    #    * @return {?Node|boolean}
    #    */
    #   function predicate(selectorOrXPath, isXPath, waitForVisible, waitForHidden) {
    #     const node = isXPath
    #       ? document.evaluate(selectorOrXPath, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue
    #       : document.querySelector(selectorOrXPath);
    #     if (!node)
    #       return waitForHidden;
    #     if (!waitForVisible && !waitForHidden)
    #       return node;
    #     const element = /** @type {Element} */ (node.nodeType === Node.TEXT_NODE ? node.parentElement : node);

    #     const style = window.getComputedStyle(element);
    #     const isVisible = style && style.visibility !== 'hidden' && hasVisibleBoundingBox();
    #     const success = (waitForVisible === isVisible || waitForHidden === !isVisible);
    #     return success ? node : null;

    #     /**
    #      * @return {boolean}
    #      */
    #     function hasVisibleBoundingBox() {
    #       const rect = element.getBoundingClientRect();
    #       return !!(rect.top || rect.bottom || rect.width || rect.height);
    #     }
    #   }
    # }

    def _detach
      @_detached = true
      # TODO
      #   for (const waitTask of this._waitTasks)
      #     waitTask.terminate(new Error('waitForFunction failed: frame got detached.'));
    end

    private

      # @param [Chromiebara::ExecutionContext, nil] context
      #
      def set_context(context)
        if context
          @_context_resolve_callback.(context)
          @_context_resolve_callback = nil
          #     this._contextResolveCallback.call(null, context);
          #     this._contextResolveCallback = null;
          #     for (const waitTask of this._waitTasks)
          #       waitTask.rerun();
        else
          @_context_promise, @_context_resolve_callback, _reject = Promise.create
          #     this._documentPromise = null;
          #     this._contextPromise = new Promise(fulfill => {
          #       this._contextResolveCallback = fulfill;
          #     });
        end
      end
  end
end
