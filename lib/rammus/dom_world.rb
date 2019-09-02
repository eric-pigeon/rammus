require 'rammus/wait_task'

module Rammus
  # @!visibility private
  #
  class DOMWorld
    extend Forwardable
    include Promise::Await

    attr_reader :frame_manager, :frame, :timeout_settings, :wait_tasks

    # @param frame_manager [Rammus::FrameManager]
    # @param frame [Rammus::Frame]
    # @param timeout_settings [Rammus::TimeoutSettings]
    #
    def initialize(frame_manager, frame, timeout_settings)
      @frame_manager = frame_manager
      @frame = frame
      @timeout_settings = timeout_settings

      # @type {?Promise<!Puppeteer.ElementHandle>}
      # this._documentPromise = null;
      # @type {!Promise<!Puppeteer.ExecutionContext>}
      @_context_promise = nil
      @_context_resolve_callback = nil
      set_context nil

      # @type {!Set<!WaitTask>}
      @wait_tasks = Set.new
      @_detached = false
    end

    # @return [boolean]
    #
    def has_context?
      @_context_resolve_callback.nil?
    end

    # @return [Rammus::ExecutionContext]
    #
    def execution_context
      raise "Execution Context is not available in detached frame \"#{frame.url}\" (are you trying to evaluate?)" if @_detached
      await @_context_promise
    end

    # (see Rammus::ExecutionContext#evaluate_handle)
    #
    def evaluate_handle(page_function, *args)
      execution_context.evaluate_handle page_function, *args
    end

    # (see Rammus::ExecutionContext#evaluate)
    #
    def evaluate(function, *args)
      execution_context.evaluate function, *args
    end

    # (see Rammus::ExecutionContext#evaluate_function)
    #
    def evaluate_function(function, *args)
      execution_context.evaluate_function function, *args
    end

    # (see Rammus::ExecutionContext#evaluate_handle_function)
    #
    def evaluate_handle_function(function, *args)
      execution_context.evaluate_handle_function function, *args
    end

    # The method queries frame for the selector. If there's no such element
    # within the frame, the method will resolve to null.
    #
    # @param selector [String] A selector to query frame for
    # @return [Rammus::ElementHandle]
    #
    def query_selector(selector)
      document.query_selector selector
    end

    # @return [Rammus::ElementHandle]
    #
    def document
      (await execution_context.evaluate_handle('document')).as_element
      # if (this._documentPromise)
      #   return this._documentPromise;
      # this._documentPromise = this.executionContext().then(async context => {
      #   const document = await context.evaluateHandle('document');
      #   return document.asElement();
      # });
      # return this._documentPromise;
    end

    # The method evaluates the XPath expression.
    #
    # @param expression [String] Expression to evaluate.
    # @return [Promise<Array<ElementHandle>>]
    #
    def xpath(expression)
      document.xpath expression
    end

    # This method runs document.querySelector within the frame and passes it
    # as the first argument to page_function. If there's no element matching
    # selector, the method throws an error.
    #
    # If page_function returns a Promise, then
    # {query_selector_evaluate_function} would wait for the promise to resolve
    # and return its value.
    #
    # @example
    #    search_value = await frame.query_selector_evaluate_function '#search', 'el => el.value'
    #    preload_href = await frame.query_selector_evaluate_function 'link[rel=preload]', 'el => el.href'
    #    html = await frame.query_selector_evaluate_function '.main-container', 'e => e.outerHTML'
    #
    # @param selector [String] A selector to query frame for
    # @param page_function [String] function(Array<Element>) Function to be evaluated in browser context
    # @param *args [Serializable,JSHandle] Arguments to pass to page_function
    #
    # @return [Promise<Object>]
    #
    def query_selector_evaluate_function(selector, page_function, *args)
      document.query_selector_evaluate_function selector, page_function, *args
    end

    # This method runs Array.from(document.querySelectorAll(selector)) within
    # the frame and passes it as the first argument to page_function.
    #
    # If page_function returns a Promise, then
    # {query_selector_all_evaluate_function} would wait for the promise to
    # resolve and return its value
    #
    # @example
    #    divs_counts = await frame.query_selector_all_evaluate_function 'div', 'divs => divs.length'
    #
    # @param selector [String] A selector to query frame for
    # @param page_function [String] function(Array<Element>) Function to be evaluated in browser context
    # @param *args [Serializable,JSHandle] Arguments to pass to page_function
    #
    # @return [Promise<Object>]
    #
    def query_selector_all_evaluate_function(selector, page_function, *args)
      document.query_selector_all_evaluate_function selector, page_function, *args
    end

    # The method runs document.querySelectorAll within the frame. If no
    # elements match the selector, the return value resolves to [].
    #
    # @param selector [String] A selector to query frame for
    # @return [Array<Rammus::ElementHandle>]
    #
    def query_selector_all(selector)
      document.query_selector_all selector
    end

    # @return [String]
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
      await evaluate_function function
    end

    # @param [String] html
    #
    def set_content(html, timeout: nil, wait_until: nil)
      wait_until ||= [:load]
      timeout ||= timeout_settings.navigation_timeout
      # We rely upon the fact that document.open() will reset frame lifecycle with "init"
      # lifecycle event. @see https://crrev.com/608658

      watcher = LifecycleWatcher.new frame_manager: frame_manager, frame: frame, wait_until: wait_until, timeout: timeout
      function = <<~JAVASCRIPT
      html => {
        document.open();
        document.write(html);
        document.close();
      }
      JAVASCRIPT
      await evaluate_function function, html

      Promise.resolve(nil).then do
        error = await Promise.race(
          watcher.timeout_or_termination_promise,
          watcher.lifecycle_promise
        )
        watcher.dispose
        raise error if error
        nil
      end
    end

    # Adds a <script> tag into the page with the desired url or content.
    #
    # @param url [String] URL of a script to be added.
    # @param path [String] Path to the JavaScript file to be injected into frame. If path is a relative path, then it is resolved relative to current working directory.
    # @param content [String] Raw JavaScript content to be injected into frame.
    # @param type [String] Script type. Use 'module' in order to load a Javascript ES6 module.
    # @return [ElementHandle] which resolves to the added tag when the script's onload fires or when the script content was injected into frame.
    #
    def add_script_tag(url: nil, path: nil, content: nil, type: '')
      # @param url [String]
      # @param type [String]
      #
      # @return [Promise<HTMLElement>]
      #
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
          return (await execution_context.evaluate_handle_function(add_script_url, url, type)).as_element
        rescue => _error
          raise "Loading script from #{url} failed"
        end
      end

      # @param content [String]
      # @param type [string]
      #
      # @return [HTMLElement]
      #
      add_script_content = <<~JAVASCRIPT
      function addScriptContent(content, type = 'text/javascript') {
        const script = document.createElement('script');
        script.type = type;
        script.text = content;
        let error = null;
        script.onerror = e => error = e;
        document.head.appendChild(script);
        if (error)
          throw error;
        return script;
      }
      JAVASCRIPT

      if path != nil
        contents = File.read path
        contents += '//# sourceURL=' + path.gsub(/\n/, '')
        return (await execution_context.evaluate_handle_function(add_script_content, contents, type)).as_element
      end

      if content != nil
        return (await execution_context.evaluate_handle_function(add_script_content, content, type)).as_element
      end

      raise 'Provide an object with a `url`, `path` or `content` property'
    end

    # Adds a <link rel="stylesheet"> tag into the page with the desired url or
    # a <style type="text/css"> tag with the content.
    #
    # @param url [String] URL of the <link> tag.
    # @param path [String] Path to the CSS file to be injected into frame. If path is a relative path, then it is resolved relative to current working directory.
    # @param content [String] Raw CSS content to be injected into frame.
    #
    # @return [ElementHandle] which resolves to the added tag when the stylesheet's onload fires or when the CSS content was injected into frame.
    #
    def add_style_tag(url: nil, path: nil, content: nil)
      # @param url [String]
      #
      # @return [Promise<HTMLElement>]
      #
      add_style_url = <<~JAVASCRIPT
      async function addStyleUrl(url) {
        const link = document.createElement('link');
        link.rel = 'stylesheet';
        link.href = url;
        const promise = new Promise((res, rej) => {
          link.onload = res;
          link.onerror = rej;
        });
        document.head.appendChild(link);
        await promise;
        return link;
      }
      JAVASCRIPT

      # @param content [String]
      #
      # @return [Promise<HTMLElement>]
      #
      add_style_content = <<~JAVASCRIPT
      async function addStyleContent(content) {
        const style = document.createElement('style');
        style.type = 'text/css';
        style.appendChild(document.createTextNode(content));
        const promise = new Promise((res, rej) => {
          style.onload = res;
          style.onerror = rej;
        });
        document.head.appendChild(style);
        await promise;
        return style;
      }
      JAVASCRIPT

      unless url.nil?
        begin
          return (await execution_context.evaluate_handle_function(add_style_url, url)).as_element
        rescue => _error
          raise "Loading style from #{url} failed"
        end
      end

      unless path.nil?
        contents = File.read path
        contents += '//# sourceURL=' + path.gsub(/\n/, '')
        return (await execution_context.evaluate_handle_function(add_style_content, contents)).as_element
      end

      unless content.nil?
        return (await execution_context.evaluate_handle_function(add_style_content, content)).as_element
      end

      raise "Provide a `url`, `path` or `content`"
    end

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

    # @param {string} selector
    # @param {!Array<string>} values
    # @return {!Promise<!Array<string>>}
    #
    def select(selector, *values)
      values.each { |value| raise "Values must be strings. Found value '#{value}' of type '#{value.class}'" unless value.is_a? String }

      select_values = <<~JAVASCRIPT
      (element, values) => {
        if (element.nodeName.toLowerCase() !== 'select')
          throw new Error('Element is not a <select> element.');

        const options = Array.from(element.options);
        element.value = undefined;
        for (const option of options) {
          option.selected = values.includes(option.value);
          if (option.selected && !element.multiple)
            break;
        }
        element.dispatchEvent(new Event('input', { 'bubbles': true }));
        element.dispatchEvent(new Event('change', { 'bubbles': true }));
        return options.filter(option => option.selected).map(option => option.value);
      }
      JAVASCRIPT

      await query_selector_evaluate_function selector, select_values, values
    end

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

    # @param {string} selector
    # @param {!{visible?: boolean, hidden?: boolean, timeout?: number}=} options
    # @return {!Promise<?Puppeteer.ElementHandle>}
    #
    def wait_for_selector(selector, visible: nil, hidden: nil, timeout: nil)
      wait_for_selector_or_xpath selector, false, visible: visible, hidden: hidden, timeout: timeout
    end

    # @param {string} xpath
    # @param {!{visible?: boolean, hidden?: boolean, timeout?: number}=} options
    # @return {!Promise<?Puppeteer.ElementHandle>}
    #
    def wait_for_xpath(xpath, visible: nil, hidden: nil, timeout: nil)
      wait_for_selector_or_xpath xpath, true, visible: visible, hidden: hidden, timeout: timeout
    end

    # @param {Function|string} pageFunction
    # @param {!{polling?: string|number, timeout?: number}=} options
    # @return {!Promise<!Puppeteer.JSHandle>}
    #
    def wait_for_function(page_function, *args, polling: 'raf', timeout: nil)
      timeout ||= timeout_settings.timeout
      WaitTask.new(self, page_function, 'function', polling, timeout, *args).promise
    end

    # @return {!Promise<string>}
    #
    def title
      await evaluate('document.title')
    end

    def _detach
      @_detached = true

      wait_tasks.each do |wait_task|
        wait_task.terminate StandardError.new('wait_for_function failed: frame got detached.')
      end
    end

    private

      # @param [Rammus::ExecutionContext, nil] context
      #
      def set_context(context)
        if context
          @_context_resolve_callback.(context)
          @_context_resolve_callback = nil
          wait_tasks.each { |wait_task| Concurrent.global_io_executor.post { wait_task.rerun } }
        else
          @_context_promise, @_context_resolve_callback, _reject = Promise.create
          # this._documentPromise = null;
        end
      end

      # @param {string} selectorOrXPath
      # @param {boolean} isXPath
      # @param {boolean} waitForVisible
      # @param {boolean} waitForHidden
      # @return {?Node|boolean}
      PREDICATE = <<~JAVASCRIPT
      function predicate(selectorOrXPath, isXPath, waitForVisible, waitForHidden) {
        const node = isXPath
          ? document.evaluate(selectorOrXPath, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue
          : document.querySelector(selectorOrXPath);
        if (!node)
          return waitForHidden;
        if (!waitForVisible && !waitForHidden)
          return node;
        const element = /** @type {Element} */ (node.nodeType === Node.TEXT_NODE ? node.parentElement : node);

        const style = window.getComputedStyle(element);
        const isVisible = style && style.visibility !== 'hidden' && hasVisibleBoundingBox();
        const success = (waitForVisible === isVisible || waitForHidden === !isVisible);
        return success ? node : null;

        /**
         * @return {boolean}
         */
        function hasVisibleBoundingBox() {
          const rect = element.getBoundingClientRect();
          return !!(rect.top || rect.bottom || rect.width || rect.height);
        }
      }
      JAVASCRIPT

      # @param {string} selectorOrXPath
      # @param {boolean} isXPath
      # @param {!{visible?: boolean, hidden?: boolean, timeout?: number}=} options
      # @return {!Promise<?Puppeteer.ElementHandle>}
      #
      def wait_for_selector_or_xpath(selector_or_xpath, is_xpath, visible: false, hidden: false, timeout: nil)
        wait_for_hidden = hidden == true
        wait_for_visible = visible == true
        timeout ||= timeout_settings.timeout
        polling = (wait_for_visible || wait_for_hidden) ? 'raf' : 'mutation'
        title = "#{is_xpath ? 'XPath' : 'selector'} \"#{selector_or_xpath}\"#{wait_for_hidden ? ' to be hidden' : ''}"
        wait_task = WaitTask.new(self, PREDICATE, title, polling, timeout, selector_or_xpath, is_xpath, wait_for_visible, wait_for_hidden)

        Promise.resolve(nil).then do
          handle = await wait_task.promise, 0

          if !handle.as_element
            handle.dispose
            next nil
          end
          handle.as_element
        end
      end
  end
end
