# frozen_string_literal: true

require 'rammus/wait_task'

module Rammus
  # @!visibility private
  #
  class DOMWorld
    extend Forwardable
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

    # The frame's default execution context.
    #
    # @return [Rammus::ExecutionContext]
    #
    def execution_context
      raise "Execution Context is not available in detached frame \"#{frame.url}\" (are you trying to evaluate?)" if @_detached

      @_context_promise.value
    end

    # (see Rammus::ExecutionContext#evaluate_handle)
    #
    def evaluate_handle(javascript)
      execution_context.evaluate_handle javascript
    end

    # (see Rammus::ExecutionContext#evaluate)
    #
    def evaluate(javascript)
      execution_context.evaluate javascript
    end

    # (see Rammus::ExecutionContext#evaluate_function)
    #
    def evaluate_function(page_function, *args)
      execution_context.evaluate_function page_function, *args
    end

    # (see Rammus::ExecutionContext#evaluate_handle_function)
    #
    def evaluate_handle_function(page_function, *args)
      execution_context.evaluate_handle_function page_function, *args
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
      execution_context.evaluate_handle('document').value.as_element
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
    # @param args [Array<Serializable,JSHandle>] Arguments to pass to page_function
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
    # @param args [Array<Serializable,JSHandle>] Arguments to pass to page_function
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

    # Gets the full HTML contents of the frame, including the doctype.
    #
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
      evaluate_function(function).value
    end

    # @param html [String] HTML markup to assign to the page.
    # @param timeout [Integer] Maximum time in milliseconds for resources to
    #   load, defaults to 2 seconds, pass 0 to disable timeout. The default
    #   value can be changed by using the
    #   {Page#set_default_navigation_timeout} or {Page#set_default_timeout}
    #   methods
    # @param wait_until [Array<Symbol>, Symbol] When to consider setting markup
    #   succeeded, defaults to load. Given an array of event strings, setting
    #   content is considered to be successful after all events have been fired.
    #   Events can be either:
    #   * :load - consider setting content to be finished when the load event is fired.
    #   * :domcontentloaded - consider setting content to be finished when the DOMContentLoaded event is fired.
    #   * :networkidle0 - consider setting content to be finished when there are no more than 0 network connections for at least 500 ms.
    #   * :networkidle2 - consider setting content to be finished when there are no more than 2 network connections for at least 500 ms.
    #
    # @return [nil]
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
      evaluate_function(function, html).wait!

      Concurrent::Promises.future do
        error = Concurrent::Promises.any(
          watcher.timeout_or_termination_promise,
          watcher.lifecycle_promise
        ).value
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
      # param url [String]
      # param type [String]
      #
      # return [Promise<HTMLElement>]
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

      unless url.nil?
        begin
          return execution_context.evaluate_handle_function(add_script_url, url, type).value.as_element
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

      unless path.nil?
        contents = File.read path
        contents += '//# sourceURL=' + path.delete("\n")
        return execution_context.evaluate_handle_function(add_script_content, contents, type).value.as_element
      end

      unless content.nil?
        return execution_context.evaluate_handle_function(add_script_content, content, type).value.as_element
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
          return execution_context.evaluate_handle_function(add_style_url, url).value!.as_element
        rescue => _error
          raise "Loading style from #{url} failed"
        end
      end

      unless path.nil?
        contents = File.read path
        contents += '//# sourceURL=' + path.delete("\n")
        return execution_context.evaluate_handle_function(add_style_content, contents).value!.as_element
      end

      unless content.nil?
        return execution_context.evaluate_handle_function(add_style_content, content).value!.as_element
      end

      raise "Provide a `url`, `path` or `content`"
    end

    # This method fetches an element with selector, scrolls it into view if
    # needed, and then uses {Page#mouse} to click in the center of the element.
    # If there's no element matching selector, the method throws an error.
    #
    # Bear in mind that if {click} triggers a navigation event and there's a
    # separate {Page#wait_for_navigation} promise to be resolved, you may end
    # up with a race condition that yields unexpected results. The correct
    # pattern for click and wait for navigation is the following:
    #
    # @example
    #    response, _ = Concurrent::Promises.zip(
    #      page.wait_for_navigation(wait_options),
    #      frame.click(selector, click_options),
    #    ).value!
    #
    # @param selector [String] A selector to search for element to click. If there are multiple elements satisfying the selector, the first will be clicked.
    # @param delay [Integer] Time to wait between mousedown and mouseup in milliseconds. Defaults to 0.
    # @param button [String] Mouse button "left", "right" or "middle" defaults to "left"
    # @param click_count [Integer] number of times to click
    #
    # @return [nil]
    #
    def click(selector, button: Mouse::Button::LEFT, click_count: 1, delay: 0)
      handle = query_selector selector
      raise "No node found for selector: #{selector}" if handle.nil?

      handle.click button: button, delay: delay, click_count: click_count
      handle.dispose
      nil
    end

    # This method fetches an element with selector and focuses it. If there's
    # no element matching selector, the method throws an error.
    #
    # @param selector [String] A selector of an element to focus. If there are
    #   multiple elements satisfying the selector, the first will be focused.
    #
    # @return [nil]
    #
    def focus(selector)
      handle = query_selector selector
      "No node found for selector: #{selector}" if handle.nil?
      handle.focus
      handle.dispose
      nil
    end

    # This method fetches an element with selector, scrolls it into view if
    # needed, and then uses {Page#mouse} to hover over the center of the element.
    # If there's no element matching selector, the method throws an error.
    #
    # @param selector [String] A selector to search for element to hover.
    #   If there are multiple elements satisfying the selector, the
    #   first will be hovered.
    #
    # @return [nil]
    #
    def hover(selector)
      handle = query_selector selector
      raise "No node found for selector: #{selector}" if handle.nil?

      handle.hover
      handle.dispose
    end

    # Triggers a change and input event once all the provided options have been
    # selected. If there's no <select> element matching selector, the method
    # throws an error.
    #
    # @example single seletion
    #   frame.select 'select#colors', 'blue'
    #
    # @example multiple selections
    #   frame.select 'select#colors', 'red', 'green', 'blue'
    #
    # @param selector [String] A selector to query frame for
    # @param values [Array<String>] Values of options to select. If the
    #   <select> has the multiple attribute, all values are considered,
    #   otherwise only the first one is taken into account.
    #
    # @return [Array<String>] An array of option values that have been
    #   successfully selected.
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

      query_selector_evaluate_function(selector, select_values, values).value!
    end

    # This method fetches an element with selector, scrolls it into view if
    # needed, and then uses page.touchscreen to tap in the center of the
    # element. If there's no element matching selector, the method throws an
    # error.
    #
    # @param selector [String] A selector to search for element to tap. If
    #   there are multiple elements satisfying the selector, the first will be
    #   tapped.
    #
    # @return [nil]
    #
    def touchscreen_tap(selector)
      handle = query_selector selector
      raise "No node found for selector: #{selector}" if handle.nil?

      handle.tap
      handle.dispose
      nil
    end

    # Sends a keydown, keypress/input, and keyup event for each character in
    # the text.
    #
    # To press a special key, like Control or ArrowDown, use {Keyboard#press}.
    #
    # @example typing instantly
    #   frame.type '#mytextarea', 'Hello'
    #
    # @example type slower like a user
    #    frame.type '#mytextarea', 'World',  delay: 0.10
    #
    # @param selector [String] A selector of an element to type into. If there
    #   are multiple elements satisfying the selector, the first will be used.
    # @param text [String] A text to type into a focused element.
    # @param delay [Integer, nil] Time to wait between key presses in
    #   seconds. Defaults to 0.
    #
    # @return [nil]
    #
    def type(selector, text, delay: nil)
      handle = query_selector selector
      raise "No node found for selector: #{selector}" if handle.nil?

      handle.type text, delay: delay
      handle.dispose
      nil
    end

    # @param selector [String]
    # @param visible [Boolean]
    # @param hidden [Boolean]
    # @param timeout [Integer, nil]
    #
    # @return [Promise<?ElementHandle>]
    #
    def wait_for_selector(selector, visible: nil, hidden: nil, timeout: nil)
      wait_for_selector_or_xpath selector, false, visible: visible, hidden: hidden, timeout: timeout
    end

    # @param xpath [String]
    # @param visible [Boolean]
    # @param hidden [Boolean]
    # @param timeout [Integer, nil]
    #
    # @return [Promise<?ElementHandle>]
    #
    def wait_for_xpath(xpath, visible: nil, hidden: nil, timeout: nil)
      wait_for_selector_or_xpath xpath, true, visible: visible, hidden: hidden, timeout: timeout
    end

    # Returns a promise that resolves when the function evaluates to true
    #
    # @example observe viewport changing size
    #    page = browser.new_page
    #    watch_dog = page.main_frame.wait_for_function 'window.innerWidth < 100'
    #    page.set_viewport width: 50, height: 50}
    #    await watch_dog
    #
    # @param page_function [Function] Function or javascript statement to be
    #   evaluated in browser context. If a function args must be not be nil
    # @param args [Array<String, JsHandle>] Arguments to pass to page_function
    # @param polling [String, Integer] An interval at which the page_function
    #   is executed, defaults to raf. If polling is a number, then it is
    #   treated as an interval in seconds at which the function would be
    #   executed. If polling is a string, then it can be one of the following
    #   values:
    #   * raf - to constantly execute page_function in requestAnimationFrame
    #     callback. This is the tightest polling mode which is suitable to
    #     observe styling changes.
    #   * mutation - to execute page_function on every DOM mutation.
    # @param timeout [Integer] maximum time to wait for in seconds. Defaults to
    #   2 seconds. Pass 0 to disable timeout. The default value can be changed
    #   by using the {Page.set_default_timeout} method.
    #
    # @return [Promise<JSHandle>] Promise which resolves when the page_function
    #   returns a truthy value. It resolves to a JSHandle of the truthy value.
    #
    def wait_for_function(page_function, *args, polling: 'raf', timeout: nil)
      timeout ||= timeout_settings.timeout
      WaitTask.new(self, page_function, 'function', polling, timeout, *args).promise
    end

    # The page's title
    #
    # @return [String]
    #
    def title
      evaluate('document.title').value
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
          wait_tasks.each(&:rerun)
        else
          @_context_promise = Concurrent::Promises.resolvable_future
          @_context_resolve_callback = @_context_promise.method(:fulfill)
          # this._documentPromise = null;
        end
      end

      # param selectorOrXPath [String]
      # param isXPath [Boolean]
      # param waitForVisible [Boolean]
      # param waitForHidden [boolean]
      #
      # return [?Node,Boolean]
      #
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

      # @param selector_or_xpath [String]
      # @param is_xpath [Boolean]
      # @param visible [Boolean]
      # @param hidden [Boolean]
      # @param timeout [Integer]
      #
      # @return [Promise<ElementHandle, nil>]
      #
      def wait_for_selector_or_xpath(selector_or_xpath, is_xpath, visible: false, hidden: false, timeout: nil)
        wait_for_hidden = hidden == true
        wait_for_visible = visible == true
        timeout ||= timeout_settings.timeout
        polling = wait_for_visible || wait_for_hidden ? 'raf' : 'mutation'
        title = "#{is_xpath ? 'XPath' : 'selector'} \"#{selector_or_xpath}\"#{wait_for_hidden ? ' to be hidden' : ''}"
        wait_task = WaitTask.new(self, PREDICATE, title, polling, timeout, selector_or_xpath, is_xpath, wait_for_visible, wait_for_hidden)

        Concurrent::Promises.future do
          handle = wait_task.promise.value!

          unless handle.as_element
            handle.dispose
            next nil
          end
          handle.as_element
        end
      end
  end
end
