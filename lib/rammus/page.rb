require 'rammus/accessibility'
require 'rammus/keyboard'
require 'rammus/mouse'
require 'rammus/touchscreen'
require 'rammus/dialog'
require 'rammus/frame_manager'
require 'rammus/console_message'
require 'rammus/emulation_manager'
require 'rammus/js_handle'
require 'rammus/coverage'
require 'rammus/timeout_settings'
require 'rammus/tracing'
require 'rammus/worker'

module Rammus
  # Page provides methods to interact with a single tab or extension background
  # page in Chromium.  One Browser instance might have multiple Page instances.
  #
  # @example create a page, navigates it to a URL, and then saves a screenshot
  #    browser = Rammus.launch
  #    page = browser.new_page
  #    page.goto 'https://example.com'
  #    page.screenshot path: 'screenshot.png'
  #    browser.close
  #
  # The Page class emits various events (described below) which can be handled
  # using on, once or remove_listener.
  #
  # @example log messages for a page load event
  #    page.once :load' -> { puts 'Page laoded! }
  #
  # @example unsubscribe from events using remove_listener method
  #   def log_request(intercepted_request)
  #     puts "A request was made: {#intercepted_request.url}"
  #   end
  #   page.on :request, method(:log_request)
  #   # Sometime later...
  #   page.remove_listener :request, method(:log_request)
  #
  class Page
    include EventEmitter
    extend Forwardable

    # @!visibility private
    #
    attr_reader :frame_manager

    # @return [Rammus::Accessibility]
    #
    attr_reader :accessibility

    # @return [Rammus::Coverage]
    #
    attr_reader :coverage

    # @return [Rammus::Keyboard]
    #
    attr_reader :keyboard

    # @return [Rammus::Mouse]
    #
    attr_reader :mouse

    # target this page was created from
    #
    # @return [Rammus::Target]
    #
    attr_reader :target

    # @return [Rammus::Touchscreen]
    #
    attr_reader :touchscreen

    # @return [Rammus::Tracing]
    #
    attr_reader :tracing

    attr_reader :javascript_enabled

    # @!method browser
    #   The browser the page belongs to
    #
    #   @return [Rammus::Browser]
    #
    # @!method browser_context
    #   The browser context the page belongs to
    #
    #   @return [Rammus::BrowserContext]
    #
    delegate [:browser, :browser_context] => :target

    # @!method main_frame
    #   Page is guaranteed to have a main frame which persists during navigations.
    #
    #   @return [Rammus::Frame]
    #
    # @!method frames
    #   Frames attached to the page
    #
    #   @return [Array<Frame>]
    #
    delegate [:frames, :main_frame, :network_manager] => :frame_manager

    # @!method authenticate(username: nil, password: nil)
    #   (see Rammus::Network::Manager#authenticate)
    #
    # @!method set_extra_http_headers(extra_http_headers)
    #   (see Rammus::Network::Manager#set_extra_http_headers)
    #
    # @!method set_offline_mode(value)
    #   (see Rammus::Network::Manager#set_offline_mode)
    #
    # @!method set_request_interception(value)
    #   (see Rammus::Network::Manager#set_request_interception)
    #
    # @!method set_user_agent(user_agent)
    #   (see Rammus::Network::Manager#set_user_agent)
    #
    delegate [
      :authenticate,
      :set_extra_http_headers,
      :set_offline_mode,
      :set_request_interception,
      :set_user_agent
    ] => :network_manager

    # @!method query_selector(selector)
    #   (see Rammus::DOMWorld#query_selector)
    #
    # @!method query_selector_all(selector)
    #    (see Rammus::DOMWorld#query_selector_all)
    #
    # @!method query_selector_all_evaluate_function(selector, page_function, *args)
    #    (see Rammus::DOMWorld#query_selector_all_evaluate_function)
    #
    # @!method query_selector_evaluate_function(selector, page_function, *args)
    #    (see Rammus::DOMWorld#query_selector_evaluate_function)
    #
    # @!method xpath(expression)
    #    (see Rammus::DOMWorld#xpath)
    #
    # @!method add_script_tag(url: nil, path: nil, content: nil, type: '' )
    #    (see Rammus::DOMWorld#add_script_tag)
    #
    # @!method add_style_tag(url: nil, path: nil, content: nil)
    #    (see Rammus::DOMWorld#add_style_tag)
    #
    # @!method click(selector, button: Mouse::Button::LEFT, click_count: 1, delay: 0)
    #    (see Rammus::Frame#click)
    #
    # @!method content
    #   Gets the full HTML contents of the page, including the doctype.
    #
    #   @return [String]
    #
    # @!method evaluate(javascript)
    #    (see Rammus::DOMWorld#evaluate)
    #
    # @!method evaluate_function(page_function, *args)
    #    (see Rammus::DOMWorld#evaluate_function)
    #
    # @!method evaluate_handle(javascript)
    #    (see Rammus::DOMWorld#evaluate_handle)
    #
    # @!method evaluate_handle_function(page_function, *args)
    #    (see Rammus::DOMWorld#evaluate_handle_function)
    #
    # @!method focus(selector)
    #    (see Rammus::Frame#focus)
    #
    # @!method goto(url, referer: nil, timeout: nil, wait_until: nil)
    #   (see Rammus::Frame#goto)
    #
    # @!method hover(selector)
    #   (see Rammus::DOMWorld#hover)
    #
    # @!method select(selector, *values)
    #   (see Rammus::DOMWorld#select)
    #
    # @!method set_content(html, timeout: nil, wait_until: nil)
    #   (see Rammus::Frame#set_content)
    #
    # @!method touchscreen_tap(selector)
    #   (see Rammus::DOMWorld#touchscreen_tap)
    #
    # @!method title
    #   (see Rammus::DOMWorld#title)
    #
    # @!method type(selector, text, delay: nil)
    #   (see Rammus::DOMWorld#type)
    #
    # @!method url
    #   (see Rammus::Frame#url)
    #
    # @!method wait_for_function(page_function, *args, polling: 'raf', timeout: nil)
    #    (see Rammus::DOMWorld#wait_for_function)
    #
    # @!method wait_for_navigation(timeout: nil, wait_until: nil)
    #   (see Rammus::Frame#wait_for_navigation)
    #
    # @!method wait_for_selector(selector, visible: nil, hidden: nil, timeout: nil)
    #   (see Rammus::Frame#wait_for_selector)
    #
    # @!method wait_for_xpath(xpath, visible: nil, hidden: nil, timeout: nil)
    #   (see Rammus::Frame#wait_for_xpath)
    #
    delegate [
      :add_script_tag,
      :add_style_tag,
      :click,
      :content,
      :evaluate,
      :evaluate_function,
      :evaluate_handle,
      :evaluate_handle_function,
      :focus,
      :goto,
      :hover,
      :query_selector,
      :query_selector_evaluate_function,
      :query_selector_all,
      :query_selector_all_evaluate_function,
      :select,
      :set_content,
      :title,
      :touchscreen_tap,
      :type,
      :url,
      :wait_for_function,
      :wait_for_navigation,
      :wait_for_selector,
      :wait_for_xpath,
      :xpath
    ] => :main_frame

    # @!visibility private
    #
    def self.create(target, default_viewport: nil, ignore_https_errors: false)
      new(target, ignore_https_errors: ignore_https_errors).tap do |page|
        Concurrent::Promises.zip(
          page.frame_manager.start,
          target.session.command(Protocol::Target.set_auto_attach auto_attach: true, wait_for_debugger_on_start: false, flatten: true),
          target.session.command(Protocol::Performance.enable),
          target.session.command(Protocol::Log.enable),
        ).wait!
        page.set_viewport default_viewport if default_viewport
      end
    end

    private_class_method :new
    # @!visibility private
    #
    def initialize(target, ignore_https_errors:)
      super()
      @_closed = false
      @target = target
      @keyboard = Keyboard.new client
      @mouse = Mouse.new client, keyboard
      @_timeout_settings = TimeoutSettings.new
      @touchscreen = Touchscreen.new client, keyboard
      @accessibility = Accessibility.new client
      @_ignore_https_errors = ignore_https_errors
      @frame_manager = FrameManager.new(client, self, ignore_https_errors, @_timeout_settings)
      @_emulation_manager = EmulationManager.new client
      @tracing = Tracing.new client
      # @type [Map<string, Function>]
      @_page_bindings = {}
      @coverage = Coverage.new client
      @javascript_enabled = true
      # @type [Viewport]
      @_viewport = nil

      # Map<String, Rammus::Worker>
      @_workers = Hash.new
      client.on Protocol::Target.attached_to_target, -> (event) do
        if event.dig("targetInfo", "type") != 'worker'
          # If we don't detach from service workers, they will never die.
          client.command Protocol::Target.detach_from_target session_id: event["sessionId"]
          next
        end
        session = ChromeClient.from_session(client).session(event["sessionId"])
        worker = Worker.new session, event["targetInfo"]["url"], method(:add_console_message), method(:handle_exception)

        @_workers[event["sessionId"]] = worker
        emit :worker_created, worker
      end

      client.on Protocol::Target.detached_from_target, -> (event) do
        next unless worker = @_workers[event["sessionId"]]
        emit :worker_destroyed, worker
        @_workers.delete event["sessionId"]
      end

      frame_manager.on :frame_attached, -> (event) { emit :frame_attached, event }
      frame_manager.on :frame_detached, -> (event) { emit :frame_detached, event }
      frame_manager.on :frame_navigated, -> (event) { emit :frame_navigated, event }

      network_manager.on :request, -> (event) { emit :request, event }
      network_manager.on :response, -> (event) { emit :response, event }
      network_manager.on :request_failed, -> (event) { emit :request_failed, event }
      network_manager.on :request_finished, -> (event) { emit :request_finished, event }

      client.on Protocol::Page.dom_content_event_fired, -> (event) { emit :dom_content_loaded }
      client.on Protocol::Page.load_event_fired, -> (_event) { emit :load }
      client.on Protocol::Runtime.console_api_called, method(:on_console_api)
      client.on Protocol::Runtime.binding_called, method(:on_binding_called)
      client.on Protocol::Page.javascript_dialog_opening, method(:on_dialog)
      client.on Protocol::Runtime.exception_thrown, ->(exception) { handle_exception exception["exceptionDetails"] }
      client.on Protocol::Inspector.target_crashed, method(:on_target_crashed)
      client.on Protocol::Performance.metrics, method(:emit_metrics)
      client.on Protocol::Log.entry_added, method(:on_log_entry_added)
      target.is_closed_promise.then do
        emit :close
        @_closed = true
      end
    end

    # Brings page to front (activates tab).
    #
    # @return [nil]
    #
    def bring_to_front
      client.command(Protocol::Page.bring_to_front).wait!
      nil
    end

    # Close the page
    #
    # @note if run_before_unload is passed as true, a beforeunload dialog might
    #   be summoned and should be handled manually via page's 'dialog' event.
    #
    # @param run_before_unload [Boolean] Defaults to false. Whether to run the
    #   before unload page handlers.
    #
    # @return [Concurrent::Promises::Future<nil>]
    #
    def close(run_before_unload: false)
      Concurrent::Promises.future do
        raise 'Protocol error: Connection closed. Most likely the page has been closed.' if client.client.closed?

        event_promise = Concurrent::Promises.resolvable_future.tap do |future|
          browser.once :target_destroyed, future.method(:resolve)
        end

        if run_before_unload
          client.command(Protocol::Page.close).wait!
        else
          client.client.command(Protocol::Target.close_target(target_id: target.target_id)).wait!
          target.is_closed_promise.wait!
        end
        event_promise.wait!
        nil
      end
    end

    # Indicates that the page has been closed.
    #
    # @return [Boolean]
    #
    def closed?
      @_closed
    end

    # Get page cookies
    #
    # If no URLs are specified, this method returns cookies for the current page
    # URL. If URLs are specified, only cookies for those URLs are returned.
    #
    # @param [Array<String>] urls
    #
    # @return [Array<Rammus::Network::Cookie>]
    #
    def cookies(*urls)
      urls = urls.length.zero? ? nil : urls
      response = client.command(Protocol::Network.get_cookies(urls: urls)).value!
      response["cookies"]
    end

    # Deletes cookies, specifying the cookie name is required.
    #
    # @param cookies [Array<Hash<name: String, url: String, domain: String, path: String>]
    #
    # @return [nil]
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
        client.command(Protocol::Network.delete_cookies(cookie)).wait!
      end
      nil
    end

    # Emulates given device metrics and user agent. This method is a shortcut
    # for calling two methods:
    #
    # * {Page#set_user_agent}
    # * {Page#set_viewport}
    #
    # To aid emulation, Rammus provides a list of device descriptors which can
    # be obtained via the {Rammus.devices}.
    #
    # page.emulate will resize the page. A lot of websites don't expect phones to change size, so you should emulate before navigating to the page.
    #
    # const puppeteer = require('puppeteer');
    # const iPhone = puppeteer.devices['iPhone 6'];
    #
    # puppeteer.launch().then(async browser => {
    #   const page = await browser.newPage();
    #   await page.emulate(iPhone);
    #   await page.goto('https://www.google.com');
    #   // other actions...
    #   await browser.close();
    # });
    # List of all available devices is available in the source code: DeviceDescriptors.js.
    #
    # options <Object>
    # viewport <Object>
    # width <number> page width in pixels.
    # height <number> page height in pixels.
    # deviceScaleFactor <number> Specify device scale factor (can be thought of as dpr). Defaults to 1.
    # isMobile <boolean> Whether the meta viewport tag is taken into account. Defaults to false.
    # hasTouch<boolean> Specifies if viewport supports touch events. Defaults to false
    # isLandscape <boolean> Specifies if viewport is in landscape mode. Defaults to false.
    # userAgent <string>
    #
    # @return [nil]
    #
    def emulate(user_agent:, viewport:)
      set_viewport viewport
      set_user_agent user_agent
      nil
    end

    # Changes the CSS media type of the page.
    #
    # @param media_type [String, nil] The only allowed values are 'screen',
    #   'print' and nil. Passing nil disables media emulation.
    #
    # @return [nil]
    #
    def emulate_media(media_type = nil)
      raise "Unsupported media type: #{media_type}" unless ['screen', 'print', nil].include? media_type
      client.command(Protocol::Emulation.set_emulated_media(media: media_type || '')).wait!
      nil
    end

    # Adds a function which would be invoked in one of the following scenarios:
    # * whenever the page is navigated
    # * whenever the child frame is attached or navigated. In this case, the
    #   function is invoked in the context of the newly attached frame
    #
    # The function is invoked after the document was created but before any of
    # its scripts were run. This is useful to amend the JavaScript environment,
    # e.g. to seed Math.random.
    #
    # @param page_function [String] Function to be evaluated in browser context
    # @param args [Array<Serializable>] Arguments to pass to page_function
    #
    # @return [nil]
    #
    def evaluate_on_new_document(page_function, *args)
      source = "(#{page_function})(#{args.map(&:to_json).join(',')})"
      client.command(Protocol::Page.add_script_to_evaluate_on_new_document(source: source)).wait!
      nil
    end

    # The method adds a function called name on the page's window object. When
    # called, the function executes rammus_function in Ruby and returns a
    # Promise which resolves to the return value of rammus_function.
    #
    # If the rammus_function returns a Promise, it will be awaited.
    #
    # @note Functions installed via {Page#expose_function} survive navigations.
    #
    # @example adding an md5 function into the page
    #   page.on :console, ->(msg) { puts msg.text }
    #   page.expose_function 'md5', ->(text) do
    #     Digest::MD5.hexdigest text
    #   end
    #   script = <<~JAVASCRIPT
    #     async () => {
    #       // use window.md5 to compute hashes
    #       const myString = 'RAMMUS';
    #       const myHash = await window.md5(myString);
    #       console.log(`md5 of ${myString} is ${myHash}`);
    #     }
    #   JAVASCRIPT
    #
    #   await page.evaluate_function script
    #
    # @example adding a window.readFile function into the page
    #   page.on :console, ->(msg) { puts msg.text }
    #   page.expose_function 'readFile' do |file_path|
    #     File.read file_path
    #   end
    #   script = <<~JAVASCRIPT
    #     async () => {
    #       // use window.readFile to read contents of a file
    #       const content = await window.readFile('/etc/hosts');
    #       console.log(content);
    #     }
    #   JAVASCRIPT
    #   await page.evaluate_function script
    #
    #
    # @overload expose_function(name, function)
    #   @param name [String] Name of the function on the window object
    #   @param function [#call] Callback function which will be called in
    #     Rammus's context.
    #
    # @overload expose_function(name, &block)
    #   @param name [String] Name of the function on the window object
    #   @yield [*args] callback which will be called in Rammus's
    #     context.
    #
    # @return [nil]
    #
    def expose_function(name, function = nil, &block)
      function ||= block
      raise "Failed to add page binding with name #{name}: window['#{name}'] already exists!" if @_page_bindings.has_key? name
      @_page_bindings[name] = function

      add_page_binding = <<~JAVASCRIPT
      function addPageBinding(bindingName) {
        const binding = window[bindingName];
        window[bindingName] = (...args) => {
          const me = window[bindingName];
          let callbacks = me['callbacks'];
          if (!callbacks) {
            callbacks = new Map();
            me['callbacks'] = callbacks;
          }
          const seq = (me['lastSeq'] || 0) + 1;
          me['lastSeq'] = seq;
          const promise = new Promise((resolve, reject) => callbacks.set(seq, {resolve, reject}));
          binding(JSON.stringify({name: bindingName, seq, args}));
          return promise;
        };
      }
      JAVASCRIPT

      expression = "(#{add_page_binding})(\"#{name}\")"
      client.command(Protocol::Runtime.add_binding(name: name)).wait!
      client.command(Protocol::Page.add_script_to_evaluate_on_new_document(source: expression)).wait!
      Concurrent::Promises.zip(*frames.map do |frame|
        frame.evaluate(expression).rescue { |error| Util.debug_error error }
      end).wait!
      nil
    end

    # Navigate to the previous page in history.
    #
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
    # @return [Rammus::Response, nil] the main resource response. In case of
    #   multiple redirects, the navigation will resolve with the response of the
    #   last redirect. If can not go back, resolves to nil
    #
    def go_back(timeout: nil, wait_until: nil)
      go(-1, timeout: timeout, wait_until: wait_until)
    end

    # Navigate to the next page in history.
    #
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
    # @return [Rammus::Response, nil] the main resource response. In case of
    #   multiple redirects, the navigation will resolve with the response of the
    #   last redirect. If can not go back, resolves to nil
    #
    def go_forward(timeout: nil, wait_until: nil)
      go(1, timeout: timeout, wait_until: wait_until)
    end

    # @note All timestamps are in monotonic time: monotonically increasing time
    #   in seconds since an arbitrary point in the past.
    #
    # @return [Rammus::Metrics]
    #
    def metrics
      response = client.command(Protocol::Performance.get_metrics).value!
      build_metrics_object response["metrics"]
    end

    def pdf(path: nil, scale: 1, display_header_footer: false,
            header_template: '', footer_template: '', print_background: false,
            landscape: false, page_ranges: '', format: nil, width: nil, height: nil,
            prefer_css_page_size: false, margin: {})

      paper_width = 8.5
      paper_height = 11

      if format
        # TODO
        #const format = Page.PaperFormats[options.format.toLowerCase()];
        #assert(format, 'Unknown paper format: ' + options.format);
        #paperWidth = format.width;
        #paperHeight = format.height;
      else
        paper_width = Page.convert_print_parameter_to_inches(width || paper_width)
        paper_height = Page.convert_print_parameter_to_inches(height || paper_height)
      end

      margin_top = Page.convert_print_parameter_to_inches(margin[:top]) || 0
      margin_left = Page.convert_print_parameter_to_inches(margin[:left]) || 0
      margin_bottom = Page.convert_print_parameter_to_inches(margin[:bottom]) || 0
      margin_right = Page.convert_print_parameter_to_inches(margin[:right]) || 0

      result = client.command(Protocol::Page.print_to_pdf(
        landscape: landscape,
        display_header_footer: display_header_footer,
        header_template: header_template,
        footer_template: footer_template,
        print_background: print_background,
        scale: scale,
        paper_width: paper_width,
        paper_height: paper_height,
        margin_top: margin_top,
        margin_bottom: margin_bottom,
        margin_left: margin_left,
        margin_right: margin_right,
        page_ranges: page_ranges,
        prefer_css_page_size: prefer_css_page_size
      )).value!
      buffer = Base64.decode64(result["data"])

      File.open(path, 'wb') { |file| file.puts buffer } if path

      buffer
    end

    # (see Rammus::ExecutionContext#query_objects)
    def query_objects(prototype_handle)
      context = main_frame.execution_context
      context.query_objects prototype_handle
    end

    # Reload the page
    #
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
    # @return [Promise<Rammus::Response, nil>] Promise which resolves to the
    #   main resource response. In case of multiple redirects, the navigation
    #   will resolve with the response of the last redirect.
    #
    def reload(timeout: nil, wait_until: nil)
      Concurrent::Promises.future do
        response, _ = Concurrent::Promises.zip(
          wait_for_navigation(timeout: timeout, wait_until: wait_until),
          client.command(Protocol::Page.reload)
        ).value!
        response
      end
    end

    # @param path [String] The file path to save the image to. The screenshot
    #   type will be inferred from file extension. If path is a relative path,
    #   then it is resolved relative to current working directory. If no path is
    #   provided, the image won't be saved to the disk.
    # @param type [String] Specify screenshot type, can be either jpeg or png.
    #   Defaults to 'png'.
    # @param quality [Integer] The quality of the image, between 0-100. Not
    #   applicable to png images.
    # @param full_page [Boolean] When true, takes a screenshot of the full
    #   scrollable page. Defaults to false.
    # @param clip [Hash] A hash which specifies clipping region of the page.
    # @option clip [Integer] :x x-coordinate of top-left corner of clip area
    # @option clip [Integer] :y y-coordinate of top-left corner of clip area
    # @option clip [Integer] :width width of clipping area
    # @option clip [Integer] :height height of clipping area
    # @param omit_background [Boolean] Hides default white background and allows
    #   capturing screenshots with transparency. Defaults to false.
    # @param encoding [String] The encoding of the image, can be either base64
    #   or binary. Defaults to binary.
    #
    # @return [String] a base64 string (depending on the value of encoding) with
    #   captured screenshot.
    #
    def screenshot(type: nil, path: nil, quality: nil, full_page: false, omit_background: false, encoding: 'binary', clip: nil)
      screenshot_type = nil
      # options.type takes precedence over inferring the type from options.path
      # because it may be a 0-length file with no extension created beforehand (i.e. as a temp file).
      if type
        raise "Unknown type value: #{type}" unless ['png', 'jpeg'].include? type
        screenshot_type = type
      elsif path
        #TODO
        #const mimeType = mime.getType(options.path);
        #if (mimeType === 'image/png')
        #  screenshotType = 'png';
        #else if (mimeType === 'image/jpeg')
        #  screenshotType = 'jpeg';
        #assert(screenshotType, 'Unsupported screenshot mime type: ' + mimeType);
      end

      screenshot_type ||= 'png'

      if quality
        raise "quality is unsupported for the #{screenshot_type} screenshots" unless screenshot_type == 'jpeg'
        # TODO
        # assert(typeof options.quality === 'number', 'Expected options.quality to be a number but found ' + (typeof options.quality));
        # assert(Number.isInteger(options.quality), 'Expected options.quality to be an integer');
        # assert(options.quality >= 0 && options.quality <= 100, 'Expected options.quality to be between 0 and 100 (inclusive), got ' + options.quality);
      end
      # TODO
      #assert(!options.clip || !options.fullPage, 'options.clip and options.fullPage are exclusive');
      #if (options.clip) {
      #  assert(typeof options.clip.x === 'number', 'Expected options.clip.x to be a number but found ' + (typeof options.clip.x));
      #  assert(typeof options.clip.y === 'number', 'Expected options.clip.y to be a number but found ' + (typeof options.clip.y));
      #  assert(typeof options.clip.width === 'number', 'Expected options.clip.width to be a number but found ' + (typeof options.clip.width));
      #  assert(typeof options.clip.height === 'number', 'Expected options.clip.height to be a number but found ' + (typeof options.clip.height));
      #  assert(options.clip.width !== 0, 'Expected options.clip.width not to be 0.');
      #  assert(options.clip.height !== 0, 'Expected options.clip.width not to be 0.');
      #}
      #return this._screenshotTaskQueue.postTask(this._screenshotTask.bind(this, screenshotType, options));
      screenshot_task screenshot_type, path: path, quality: quality, full_page: full_page, omit_background: omit_background, encoding: encoding, clip: clip
    end

    # Toggles bypassing page's Content-Security-Policy.
    #
    # @note CSP bypassing happens at the moment of CSP initialization rather
    #   then evaluation. Usually this means that page.setBypassCSP should be
    #   called before navigating to the domain.
    #
    # @param enabled [Boolean] sets bypassing of page's Content-Security-Policy
    #
    # @return [nil]
    #
    def set_bypass_csp(enabled)
      client.command(Protocol::Page.set_bypass_csp(enabled: enabled)).wait!
      nil
    end

    # Toggles ignoring cache for each request based on the enabled state. By
    # default, caching is enabled.
    #
    # @param enabled [Boolean] sets the enabled state of the cache.
    #
    # @return [nil]
    #
    def set_cache_enabled(enabled = true)
      network_manager.set_cache_enabled enabled
      nil
    end

    # @param [Array<Network::CookieParam>] cookies
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
        client.command(Protocol::Network.set_cookies(cookies: cookies)).wait!
      end
    end

    # This setting will change the default maximum navigation time for the
    # following methods and related shortcuts:
    # * {Page#go_back}
    # * {Page#go_forward}
    # * {Page#goto}
    # * {Page#reload}
    # * {Page#set_content}
    # * {Page#wait_for_navigation}
    #
    # @note {set_default_navigation_timeout} takes priority over
    #   {set_default_timeout}
    #
    # @param timeout [Integer] Maximum navigation time in seconds
    #
    # @return [nil]
    #
    def set_default_navigation_timeout(timeout)
      @_timeout_settings.set_default_navigation_timeout timeout
      nil
    end

    # This setting will change the default maximum time for the following
    # methods and related shortcuts:
    # * {Page#go_back}
    # * {Page#go_forward}
    # * {Page#goto}
    # * {Page#reload}
    # * {Page#set_content}
    # * {Page#wait_for_function}
    # * {Page#wait_for_navigation}
    # * {Page#wait_for_request}
    # * {Page#wait_for_response}
    # * {Page#wait_for_selector}
    # * {Page#wait_for_xpath}
    #
    # @param timeout [Numeric] Maximum time in seconds
    #
    # @return [nil]
    #
    def set_default_timeout(timeout)
      @_timeout_settings.timeout = timeout
      nil
    end

    # Sets the page's geolocation.
    #
    # @param longitude [Numberic] Longitude between -180 and 180.
    # @param latitude [Numberic] Latitude between -90 and 90.
    # @param accuracy [Numberic, nil] Optional non-negative accuracy value.
    #
    # @return [nil]
    #
    def set_geolocation(longitude:, latitude:, accuracy: 0)
      raise "Invalid longitude '#{longitude}': precondition -180 <= LONGITUDE <= 180 failed." if longitude < -180 || longitude > 180
      raise "Invalid latitude '#{latitude}': precondition -90 <= LATITUDE <= 90 failed." if latitude < -90 || latitude > 90
      raise "Invalid accuracy '#{accuracy}': precondition 0 <= ACCURACY failed." if accuracy < 0

      client.command(Protocol::Emulation.set_geolocation_override(longitude: longitude, latitude: latitude, accuracy: accuracy)).wait!
      nil
    end

    # Enable or disable JavaScript for the page
    #
    # @param enabled [Boolean] Whether or not to enable JavaScript on the page.
    #
    # @note changing this value won't affect scripts that have already been run.
    # It will take full effect on the next navigation.
    #
    def set_javascript_enabled(enabled)
      return if javascript_enabled == enabled

      @javascript_enabled = enabled
      client.command Protocol::Emulation.set_script_execution_disabled value: !javascript_enabled
    end

    # Change the page viewport size
    #
    # In the case of multiple pages in a single browser, each page can have its
    # own viewport size.
    #
    # {Page.set_viewport} will resize the page. A lot of websites don't expect
    # phones to change size, so you should set the viewport before navigating to
    # the page.
    #
    # @note in certain cases, setting viewport will reload the page in order to
    #   set the is_mobile or has_touch properties.
    #
    # @param width [Integer] page width in pixels
    # @param height [Integer] page height in pixels
    # @param device_scale_factor [Integer] Specify device scale factor (can be
    #   thought of as dpr). Defaults to 1.
    # @param is_mobile [Integer] Whether the meta viewport tag is taken into
    #   account. Defaults to false.
    # @param has_touch [Boolean] Specifies if viewport supports touch events.
    #   Defaults to false
    # @param is_landscape [Boolean] Specifies if viewport is in landscape mode.
    #   Defaults to false.
    #
    # @return [nil]
    #
    def set_viewport(width:, height:, device_scale_factor: 1, is_mobile: false, has_touch: false, is_landscape: false)
      viewport = {
        width: width,
        height: height,
        device_scale_factor: device_scale_factor,
        is_mobile: is_mobile,
        has_touch: has_touch,
        is_landscape: is_landscape
      }.compact
      needs_reload = @_emulation_manager.emulate_viewport viewport
      @_viewport = viewport

      reload.wait if needs_reload
      nil
    end

    # Page viewport
    #
    # @return [Hash]
    #   * width [Integer] page width in pixels.
    #   * height [Integer] page height in pixels.
    #   * device_scale_factor [Integer] Specify device scale factor (can be though of as dpr). Defaults to 1.
    #   * is_mobile [Boolean] Whether the meta viewport tag is taken into account. Defaults to false.
    #   * has_touch [Boolean] Specifies if viewport supports touch events. Defaults to false
    #   * is_landscape [Boolean] Specifies if viewport is in landscape mode. Defaults to false.
    #
    def viewport
      @_viewport
    end

    # Wait for a request
    #
    # @param url_or_predicate [String, #call] A URL or predicate to wait for.
    # @param timeout [Numberic] Maximum wait time in seconds, defaults to 2
    #   seconds, pass 0 to disable the timeout. The default value can be changed
    #   by using the {Page#set_default_timeout} method.
    #
    # @return [Promise<Request>] Promise which resolves to the matched request.
    #
    def wait_for_request(url_or_predicate = nil, timeout: nil, &block)
      timeout ||= @_timeout_settings.timeout
      url_or_predicate ||= block
      Util.wait_for_event(network_manager, :request, timeout, session_closed_future) do |request|
        if url_or_predicate.is_a? String
          next url_or_predicate == request.url
        end
        if url_or_predicate.respond_to?(:call)
          next !!url_or_predicate.call(request)
        end
        false
      end
    end

    # @param url_or_predicate [String, #call] A URL or predicate to wait for.
    # @param timeout [Numeric] Maximum wait time in seconds, defaults to 2
    #   seconds, pass 0 to disable the timeout. The default value can be changed
    #   by using the {Page#set_default_timeout} method.
    #
    # @return [Promise<Response>] Promise which resolves to the matched response.
    #
    def wait_for_response(url_or_predicate = nil, timeout: nil, &block)
      timeout ||= @_timeout_settings.timeout
      url_or_predicate ||= block
      Util.wait_for_event(network_manager, :response, timeout, session_closed_future) do |response|
        if url_or_predicate.is_a? String
          next url_or_predicate == response.url
        end
        if url_or_predicate.respond_to?(:call)
          next !!url_or_predicate.call(response)
        end
        false
      end
    end

    # Page workers
    #
    # @note This does not contain ServiceWorkers
    #
    # @return [Array<Rammus::Worker>] all of the dedicated WebWorkers associated
    #   with the page.
    #
    def workers
      @_workers.values
    end

    def inspect
      "#<#{self.class}:0x#{object_id} #{viewport}>"
    end

    private

      def client
        @client ||= target.session
      end

      def event_queue
        client.send :event_queue
      end

      def on_target_crashed(_event)
        emit :error, Errors::PageCrashed.new('Page crashed!')
      end

      def on_log_entry_added(event)
        level = event["entry"]["level"]
        text = event["entry"]["text"]
        args = event["entry"]["args"]
        url = event["entry"]["url"]
        line_number = event["entry"]["line_number"]
        args.map { |arg| Util.release_object client, arg } if event.dig "entry", "args"
        if event.dig("entry", "source") != 'worker'
          emit :console, ConsoleMessage.new(level, text, [], url: url, line_number: line_number)
        end
      end

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

      def handle_exception(exception_details)
        message = Util.get_exception_message exception_details
        error = StandardError.new message
        emit :page_error, error
      end

      def on_console_api(event)
        if event["executionContextId"] == 0
          # DevTools protocol stores the last 1000 console messages. These
          # messages are always reported even for removed execution contexts. In
          # this case, they are marked with executionContextId = 0 and are
          # reported upon enabling Runtime agent.
          #
          # Ignore these messages since:
          # - there's no execution context we can use to operate with message
          #   arguments
          # - these messages are reported before Puppeteer clients can subscribe
          #   to the 'console'
          #   page event.
          #
          # @see https://github.com/GoogleChrome/puppeteer/issues/3865
          return
        end
        context = frame_manager.execution_context_by_id event["executionContextId"]
        values = event["args"].map { |arg| JSHandle.create_js_handle context, arg }
        add_console_message event["type"], values, event["stackTrace"]
      end

      def add_console_message(type, args, stack_trace)
        if listener_count(:console).zero?
          args.each  { |arg| arg.dispose }
          return
        end
        text_tokens = args.map do |arg|
          remote_object = arg.remote_object
          if remote_object["objectId"]
            arg.to_s
          else
            Util.value_from_remote_object remote_object
          end
        end
        location = if stack_trace && stack_trace["callFrames"].length
                    {
                      url: stack_trace.dig("callFrames", 0, "url"),
                      line_number: stack_trace.dig("callFrames", 0, "lineNumber"),
                      column_number: stack_trace.dig("callFrames", 0, "columnNumber")
                    }
                   else
                     {}
                   end
        message = ConsoleMessage.new type, text_tokens.join(' '), args, location
        emit(:console, message)
      end

      def go(delta, timeout: nil, wait_until: nil)
        history = client.command(Protocol::Page.get_navigation_history).value!
        entry = history["entries"][history["currentIndex"] + delta]
        return if entry.nil?
        response, _ = Concurrent::Promises.zip(
         wait_for_navigation(timeout: timeout, wait_until: wait_until),
         client.command(Protocol::Page.navigate_to_history_entry entry_id: entry["id"])
        ).value!
        response
      end

      SUPPORTED_METRICS = [
        'Timestamp',
        'Documents',
        'Frames',
        'JSEventListeners',
        'Nodes',
        'LayoutCount',
        'RecalcStyleCount',
        'LayoutDuration',
        'RecalcStyleDuration',
        'ScriptDuration',
        'TaskDuration',
        'JSHeapUsedSize',
        'JSHeapTotalSize',
      ]

      def build_metrics_object(metrics = [])
        metrics.map do |metric|
          next unless SUPPORTED_METRICS.include? metric["name"]
          [metric["name"], metric["value"]]
        end.compact.to_h
      end

      def emit_metrics(event)
        emit :metrics, {
          "title" => event["title"],
          "metrics" => build_metrics_object(event["metrics"])
        }
      end

      def on_binding_called(event)
        payload = JSON.parse event["payload"]
        name = payload["name"]
        seq = payload["seq"]
        args = payload["args"]

        # @param {string} name
        # @param [Numeric] seq
        # @param {*} result
        #
        deliver_result = <<~JAVASCRIPT
        function deliverResult(name, seq, result) {
          window[name]['callbacks'].get(seq).resolve(result);
          window[name]['callbacks'].delete(seq);
        }
        JAVASCRIPT

        expression =
          begin
            result = @_page_bindings[name].call(*args)
            result = result.value! if result.is_a?(Concurrent::Promises::Future)
            Util.evaluation_string deliver_result, name, seq, result
          rescue => error
            # @param {string} name
            # @param [Numeric] seq
            # @param {string} message
            # @param {string} stack
            #
            deliver_error = <<~JAVASCRIPT
            function deliverError(name, seq, message, stack) {
              const error = new Error(message);
              error.stack = stack;
              window[name]['callbacks'].get(seq).reject(error);
              window[name]['callbacks'].delete(seq);
            }
            JAVASCRIPT

            Util.evaluation_string deliver_error, name, seq, error.message, error.backtrace
          end
        client.command Protocol::Runtime.evaluate expression: expression, context_id: event["executionContextId"]
      end

      UNIT_TO_PIXELS = {
        'px' => 1,
        'in' => 96,
        'cm' => 37.8,
        'mm' => 3.78
      }

      # @param parameter [String, Numeric, nil]
      #
      # @return [Numeric, nil]
      #
      def self.convert_print_parameter_to_inches(parameter)
        return if parameter.nil?

        pixels = nil
        if parameter.is_a? Numeric
          # Treat numbers as pixel values to be aligned with phantom's paperSize.
          pixels = parameter
        elsif parameter.is_a? String
          text = parameter
          unit = text[-2..-1]
          value_text = ''
          if UNIT_TO_PIXELS.has_key? unit
            value_text = text[0..-3]
          else
            # In case of unknown unit try to parse the whole parameter as number of pixels.
            # This is consistent with phantom's paperSize behavior.
            unit = 'px'
            value_text = text
          end
          value = value_text.to_i
          "Failed to parse parameter value: #{text}" if value.zero?
          pixels = value * UNIT_TO_PIXELS[unit]
        else
          raise "page.pdf() Cannot handle parameter type: #{parameter.class}"
        end

        pixels.to_f / 96
      end

      def screenshot_task(format, clip: nil, quality: nil, full_page: false, omit_background: false, encoding: 'binary', path: nil)
        client.command(Protocol::Target.activate_target(target_id: target.target_id)).wait!
        clip = unless clip.nil?
                 x = clip[:x].round
                 y = clip[:y].round
                 width = (clip[:width] + clip[:x] - x).round
                 height = (clip[:height] + clip[:y] - y).round

                 { x: x, y: y, width: width, height: height, scale: 1 }
               end

        if full_page
          metrics = client.command(Protocol::Page.get_layout_metrics).value!
          width = metrics.dig("contentSize", "width").ceil
          height = metrics.dig("contentSize", "height").ceil

          # Overwrite clip for full page at all times.
          clip = { x: 0, y: 0, width: width, height: height, scale: 1 }
          is_mobile = @_viewport.fetch :is_mobile, false
          device_scale_factor = @_viewport.fetch :device_scale_factor, 1
          is_landscape = @_viewport.fetch :is_landscape, false
          # @type {!Protocol.Emulation.ScreenOrientation}
          screen_orientation = is_landscape ? { angle: 90, type: 'landscapePrimary' } : { angle: 0, type: 'portraitPrimary' }
          client.command(Protocol::Emulation.set_device_metrics_override(
            mobile: is_mobile,
            width: width,
            height: height,
            device_scale_factor: device_scale_factor,
            screen_orientation: screen_orientation
          )).wait!
        end

        should_set_default_background = omit_background && format == 'png'
        if should_set_default_background
          client.command(Protocol::Emulation.set_default_background_color_override(color: { r: 0, g: 0, b: 0, a: 0 })).wait!
        end
        result = client.command(Protocol::Page.capture_screenshot(format: format, quality: quality, clip: clip)).value!

        if should_set_default_background
          client.command(Protocol::Emulation.set_default_background_color_override(color: nil)).wait!
        end

        if full_page && viewport
          set_viewport @_viewport
        end

        buffer = encoding == 'base64' ? result["data"] : Base64.decode64(result["data"])

        File.open(path, 'wb') { |file| file.puts buffer } if path

        buffer
      end

      def session_closed_future
        @_session_closed_future ||= Concurrent::Promises.resolvable_future.tap do |future|
          client.once :cdp_session_disconnected, -> (_event) { future.fulfill(StandardError.new('Target closed')) }
        end
      end
  end
end
