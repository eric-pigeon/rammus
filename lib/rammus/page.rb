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
  # page in Chromium.
  #
  # One Browser instance might have multiple Page instances.
  #
  class Page
    include Promise::Await
    include EventEmitter
    extend Promise::Await
    extend Forwardable

    attr_reader :target, :frame_manager, :javascript_enabled, :keyboard, :mouse,
      :touchscreen, :accessibility, :coverage, :tracing

    delegate [:browser, :browser_context] => :target
    delegate [:frames, :main_frame, :network_manager] => :frame_manager
    delegate [
      :authenticate,
      :set_extra_http_headers,
      :set_offline_mode,
      :set_request_interception,
      :set_user_agent
    ] => :network_manager
    delegate [
      :add_script_tag,
      :add_style_tag,
      :click,
      :content,
      :evaluate,
      :evaluate_function,
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
    def self.create(target, default_viewport: nil, ignore_https_errors: false)
      new(target, ignore_https_errors: ignore_https_errors).tap do |page|
        await Promise.all(
          page.frame_manager.start,
          target.session.command(Protocol::Target.set_auto_attach auto_attach: true, wait_for_debugger_on_start: false, flatten: true),
          target.session.command(Protocol::Performance.enable),
          target.session.command(Protocol::Log.enable),
        )
        page.set_viewport default_viewport if default_viewport
      end
    end

    private_class_method :new
    # @!visibility private
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
      # @type {!Map<string, Function>}
      @_page_bindings = {}
      @coverage = Coverage.new client
      @javascript_enabled = true
      # @type {?Puppeteer.Viewport}
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

    # Sets the page's geolocation.
    #
    # @param [Numberic] longitude
    # @param [Numberic] latitude
    # @param [Numberic, nil] accuracy
    #
    def set_geolocation(longitude:, latitude:, accuracy: 0)
      raise "Invalid longitude '#{longitude}': precondition -180 <= LONGITUDE <= 180 failed." if longitude < -180 || longitude > 180
      raise "Invalid latitude '#{latitude}': precondition -90 <= LATITUDE <= 90 failed." if latitude < -90 || latitude > 90
      raise "Invalid accuracy '#{accuracy}': precondition 0 <= ACCURACY failed." if accuracy < 0

      await client.command Protocol::Emulation.set_geolocation_override longitude: longitude, latitude: latitude, accuracy: accuracy
    end

    # @return [Array<Rammus::Worker>]
    #
    def workers
      @_workers.values
    end

    # @param [Numberic] timeout
    #
    def set_default_navigation_timeout(timeout)
      @_timeout_settings.set_default_navigation_timeout timeout
    end

    # @param [Numeric] timeout
    #
    def set_default_timeout(timeout)
      @_timeout_settings.timeout = timeout
    end

    # @param [String} page_function
    # @param [Array<*>] args
    #
    # @return [Promise<Rammus::JSHandle>]
    #
    def evaluate_handle(page_function, *args)
      context = main_frame.execution_context
      context.evaluate_handle page_function, *args
    end

    # @param [String[ page_function
    # @param [Array<*>] args
    #
    # @return [Promise<Rammus::JSHandle>]
    #
    def evaluate_handle_function(page_function, *args)
      context = main_frame.execution_context
      context.evaluate_handle_function page_function, *args
    end

    # @param [Rammus::JSHandle] prototype_handle
    #
    # @return [Rammus::JSHandle]
    #
    def query_objects(prototype_handle)
      context = main_frame.execution_context
      context.query_objects prototype_handle
    end

    # If no URLs are specified, this method returns cookies for the current page
    # URL. If URLs are specified, only cookies for those URLs are returned.
    #
    # @param [Array<String>] urls
    #
    # @return [Array<Rammus::Network::Cookie>]
    #
    def cookies(*urls)
      urls = urls.length.zero? ? nil : urls
      response = await client.command Protocol::Network.get_cookies urls: urls
      response["cookies"]
    end

    # @param [Array<Protocol.Network.delete_cookies_parameters>] cookies
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
        await client.command Protocol::Network.set_cookies cookies: cookies
      end
    end

    # @param [String] name
    # @param [#call] function
    # TODO document block
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
      await client.command Protocol::Runtime.add_binding name: name
      await client.command Protocol::Page.add_script_to_evaluate_on_new_document source: expression
      Promise.all(*frames.map { |frame| frame.evaluate(expression).catch { |error| Util.debug_error error  } })
    end

    # @return [Rammus::Metrics]
    #
    def metrics
      response = await client.command Protocol::Performance.get_metrics
      build_metrics_object response["metrics"]
    end

    # @param timeout [Numeric]
    # @param wait_until [Symbol, Array<Symbol>]
    #
    # @return [Promise<Rammus::Response, nil>]
    #
    def reload(timeout: nil, wait_until: nil)
      Promise.resolve(nil).then do
        response, _ = await Promise.all(
          wait_for_navigation(timeout: timeout, wait_until: wait_until),
          client.command(Protocol::Page.reload)
        )
        response
      end
    end

    # @param [String] url_or_predicate
    # @param [Numeric] timeout
    #
    # TODO document block
    #
    # @return [Promise<Rammus::Request>]
    #
    def wait_for_request(url_or_predicate = nil, timeout: nil, &block)
      timeout ||= @_timeout_settings.timeout
      url_or_predicate ||= block
      Util.wait_for_event(network_manager, :request, -> (request) do
        if url_or_predicate.is_a? String
          next url_or_predicate == request.url
        end
        if url_or_predicate.respond_to?(:call)
          next !!url_or_predicate.call(request)
        end
        false
      end)
    end

    # @param {(string|Function)} urlOrPredicate
    # @param {!{timeout?: number}=} options
    # @return {!Promise<!Puppeteer.Response>}
    #
    def wait_for_response(url_or_predicate = nil, timeout: nil, &block)
      timeout ||= @_timeout_settings.timeout
      url_or_predicate ||= block
      Util.wait_for_event(network_manager, :response, -> (response) do
        if url_or_predicate.is_a? String
          next url_or_predicate == response.url
        end
        if url_or_predicate.respond_to?(:call)
          next !!url_or_predicate.call(response)
        end
        false
      end)
    end

    # @param {!{timeout?: number, waitUntil?: string|!Array<string>}=} options
    # @return {!Promise<?Puppeteer.Response>}
    #
    def go_back(timeout: nil, wait_until: nil)
      go(-1, timeout: timeout, wait_until: wait_until)
    end

    # @param {!{timeout?: number, waitUntil?: string|!Array<string>}=} options
    # @return {!Promise<?Puppeteer.Response>}
    #
    def go_forward(timeout: nil, wait_until: nil)
      go(1, timeout: timeout, wait_until: wait_until)
    end

    def bring_to_front
      await client.command Protocol::Page.bring_to_front
    end

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

    # @param [Boolean] enabled
    #
    def set_bypass_csp(enabled)
      await client.command Protocol::Page.set_bypass_csp enabled: enabled
    end

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

      await reload if needs_reload
    end

    # @return {?Puppeteer.Viewport}
    #
    def viewport
      @_viewport
    end

    # @param {Function|string} pageFunction
    # @param {!Array<*>} args
    #
    def evaluate_on_new_document(page_function, *args)
      source = "(#{page_function})(#{args.map(&:to_json).join(',')})"
      await client.command Protocol::Page.add_script_to_evaluate_on_new_document source: source
    end

    # @param {boolean} enabled
    #
    def set_cache_enabled(enabled = true)
      network_manager.set_cache_enabled enabled
    end

    # @param {!ScreenshotOptions=} options
    # @return {!Promise<!Buffer|!String>}
    #
    def screenshot(type: nil, path: nil, quality: nil, **options)
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
      screenshot_task screenshot_type, { path: path, quality: quality }.merge(options) # TODO
    end

    # @param {"png"|"jpeg"} format
    # @param {!ScreenshotOptions=} options
    # @return {!Promise<!Buffer|!String>}
    #
    def screenshot_task(format, clip: nil, quality: nil, full_page: false, omit_background: false, encoding: 'binary', path: nil)
      await client.command Protocol::Target.activate_target(target_id: target.target_id)
      clip = unless clip.nil?
               x = clip[:x].round
               y = clip[:y].round
               width = (clip[:width] + clip[:x] - x).round
               height = (clip[:height] + clip[:y] - y).round

               { x: x, y: y, width: width, height: height, scale: 1 }
             end

      if full_page
        metrics = await client.command Protocol::Page.get_layout_metrics
        width = metrics.dig("contentSize", "width").ceil
        height = metrics.dig("contentSize", "height").ceil

        # Overwrite clip for full page at all times.
        clip = { x: 0, y: 0, width: width, height: height, scale: 1 }
        is_mobile = @_viewport.fetch :is_mobile, false
        device_scale_factor = @_viewport.fetch :device_scale_factor, 1
        is_landscape = @_viewport.fetch :is_landscape, false
        # @type {!Protocol.Emulation.ScreenOrientation}
        screen_orientation = is_landscape ? { angle: 90, type: 'landscapePrimary' } : { angle: 0, type: 'portraitPrimary' }
        await client.command Protocol::Emulation.set_device_metrics_override(
          mobile: is_mobile,
          width: width,
          height: height,
          device_scale_factor: device_scale_factor,
          screen_orientation: screen_orientation
        )
      end

      should_set_default_background = omit_background && format == 'png'
      if should_set_default_background
        await client.command Protocol::Emulation.set_default_background_color_override(color: { r: 0, g: 0, b: 0, a: 0 })
      end
      result = await client.command Protocol::Page.capture_screenshot(format: format, quality: quality, clip: clip)

      if should_set_default_background
        await client.command Protocol::Emulation.set_default_background_color_override(color: nil)
      end

      if full_page && viewport
        set_viewport @_viewport
      end

      buffer = encoding == 'base64' ? result["data"] : Base64.decode64(result["data"])

      File.open(path, 'wb') { |file| file.puts buffer } if path

      buffer
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

      result = await client.command Protocol::Page.print_to_pdf(
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
      )
      buffer = Base64.decode64(result["data"])

      File.open(path, 'wb') { |file| file.puts buffer } if path

      buffer
    end

    def close(run_before_unload: false)
      raise 'Protocol error: Connection closed. Most likely the page has been closed.' if client.client.closed?
      if run_before_unload
        await client.command Protocol::Page.close
      else
        await client.client.command Protocol::Target.close_target target_id: target.target_id
        await target.is_closed_promise
      end
    end

    # @return [Boolean]
    #
    def is_closed?
      @_closed
    end

    private

      def client
        @client ||= target.session
      end

      def on_target_crashed(_event)
        emit :error, PageCrashed.new('Page crashed!')
      end

      #  @param {!Protocol.Log.entryAddedPayload} event
      #
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

      # @param {!Protocol.Runtime.ExceptionDetails} exceptionDetails
      #
      def handle_exception(exception_details)
        message = Util.get_exception_message exception_details
        error = StandardError.new message
        emit :page_error, error
      end

      # @param {!Protocol.Runtime.consoleAPICalledPayload} event
      #
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

      # @param {string} type
      # @param {!Array<!Puppeteer.JSHandle>} args
      # @param {Protocol.Runtime.StackTrace=} stackTrace
      #
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

      # @param {!{timeout?: number, waitUntil?: string|!Array<string>}=} options
      # @return {!Promise<?Puppeteer.Response>}
      #
      def go(delta, timeout: nil, wait_until: nil)
        history = await client.command Protocol::Page.get_navigation_history
        entry = history["entries"][history["currentIndex"] + delta]
        return if entry.nil?
        response, _ = await Promise.all(
         wait_for_navigation(timeout: timeout, wait_until: wait_until),
         client.command(Protocol::Page.navigate_to_history_entry entry_id: entry["id"])
        )
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

      # @param {?Array<!Protocol.Performance.Metric>} metrics
      # @return {!Metrics}
      #
      def build_metrics_object(metrics = [])
        metrics.map do |metric|
          next unless SUPPORTED_METRICS.include? metric["name"]
          [metric["name"], metric["value"]]
        end.compact.to_h
      end

      # @param {!Protocol.Performance.metricsPayload} event
      #
      def emit_metrics(event)
        emit :metrics, {
          "title" => event["title"],
          "metrics" => build_metrics_object(event["metrics"])
        }
      end

      # @param {!Protocol.Runtime.bindingCalledPayload} event
      #
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
            result = await result if result.is_a?(Promise)
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

      # @param {(string|number|undefined)} parameter
      # @return {(number|undefined)}
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
  end
end
