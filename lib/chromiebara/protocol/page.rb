module Chromiebara
  module Protocol
    module Page
      extend self

      # Deprecated, please use addScriptToEvaluateOnNewDocument instead.
      #
      #
      def add_script_to_evaluate_on_load(script_source:)
        {
          method: "Page.addScriptToEvaluateOnLoad",
          params: { scriptSource: script_source }.compact
        }
      end

      # Evaluates given script in every frame upon creation (before loading frame's scripts).
      #
      # @param world_name [String] If specified, creates an isolated world with the given name and evaluates given script in it. This world name will be used as the ExecutionContextDescription::name when the corresponding event is emitted.
      #
      def add_script_to_evaluate_on_new_document(source:, world_name: nil)
        {
          method: "Page.addScriptToEvaluateOnNewDocument",
          params: { source: source, worldName: world_name }.compact
        }
      end

      # Brings page to front (activates tab).
      #
      #
      def bring_to_front
        {
          method: "Page.bringToFront"
        }
      end

      # Capture page screenshot.
      #
      # @param format [String] Image compression format (defaults to png).
      # @param quality [Integer] Compression quality from range [0..100] (jpeg only).
      # @param clip [Viewport] Capture the screenshot of a given region only.
      # @param from_surface [Boolean] Capture the screenshot from the surface, rather than the view. Defaults to true.
      #
      def capture_screenshot(format: nil, quality: nil, clip: nil, from_surface: nil)
        {
          method: "Page.captureScreenshot",
          params: { format: format, quality: quality, clip: clip, fromSurface: from_surface }.compact
        }
      end

      # Returns a snapshot of the page as a string. For MHTML format, the serialization includes
      # iframes, shadow DOM, external resources, and element-inline styles.
      #
      # @param format [String] Format (defaults to mhtml).
      #
      def capture_snapshot(format: nil)
        {
          method: "Page.captureSnapshot",
          params: { format: format }.compact
        }
      end

      # Clears the overriden device metrics.
      #
      #
      def clear_device_metrics_override
        {
          method: "Page.clearDeviceMetricsOverride"
        }
      end

      # Clears the overridden Device Orientation.
      #
      #
      def clear_device_orientation_override
        {
          method: "Page.clearDeviceOrientationOverride"
        }
      end

      # Clears the overriden Geolocation Position and Error.
      #
      #
      def clear_geolocation_override
        {
          method: "Page.clearGeolocationOverride"
        }
      end

      # Creates an isolated world for the given frame.
      #
      # @param frame_id [Frameid] Id of the frame in which the isolated world should be created.
      # @param world_name [String] An optional name which is reported in the Execution Context.
      # @param grant_univeral_access [Boolean] Whether or not universal access should be granted to the isolated world. This is a powerful option, use with caution.
      #
      def create_isolated_world(frame_id:, world_name: nil, grant_univeral_access: nil)
        {
          method: "Page.createIsolatedWorld",
          params: { frameId: frame_id, worldName: world_name, grantUniveralAccess: grant_univeral_access }.compact
        }
      end

      # Deletes browser cookie with given name, domain and path.
      #
      # @param cookie_name [String] Name of the cookie to remove.
      # @param url [String] URL to match cooke domain and path.
      #
      def delete_cookie(cookie_name:, url:)
        {
          method: "Page.deleteCookie",
          params: { cookieName: cookie_name, url: url }.compact
        }
      end

      # Disables page domain notifications.
      #
      #
      def disable
        {
          method: "Page.disable"
        }
      end

      # Enables page domain notifications.
      #
      #
      def enable
        {
          method: "Page.enable"
        }
      end


      #
      #
      def get_app_manifest
        {
          method: "Page.getAppManifest"
        }
      end

      # Returns all browser cookies. Depending on the backend support, will return detailed cookie
      # information in the `cookies` field.
      #
      #
      def get_cookies
        {
          method: "Page.getCookies"
        }
      end

      # Returns present frame tree structure.
      #
      #
      def get_frame_tree
        {
          method: "Page.getFrameTree"
        }
      end

      # Returns metrics relating to the layouting of the page, such as viewport bounds/scale.
      #
      #
      def get_layout_metrics
        {
          method: "Page.getLayoutMetrics"
        }
      end

      # Returns navigation history for the current page.
      #
      #
      def get_navigation_history
        {
          method: "Page.getNavigationHistory"
        }
      end

      # Resets navigation history for the current page.
      #
      #
      def reset_navigation_history
        {
          method: "Page.resetNavigationHistory"
        }
      end

      # Returns content of the given resource.
      #
      # @param frame_id [Frameid] Frame id to get resource for.
      # @param url [String] URL of the resource to get content for.
      #
      def get_resource_content(frame_id:, url:)
        {
          method: "Page.getResourceContent",
          params: { frameId: frame_id, url: url }.compact
        }
      end

      # Returns present frame / resource tree structure.
      #
      #
      def get_resource_tree
        {
          method: "Page.getResourceTree"
        }
      end

      # Accepts or dismisses a JavaScript initiated dialog (alert, confirm, prompt, or onbeforeunload).
      #
      # @param accept [Boolean] Whether to accept or dismiss the dialog.
      # @param prompt_text [String] The text to enter into the dialog prompt before accepting. Used only if this is a prompt dialog.
      #
      def handle_java_script_dialog(accept:, prompt_text: nil)
        {
          method: "Page.handleJavaScriptDialog",
          params: { accept: accept, promptText: prompt_text }.compact
        }
      end

      # Navigates current page to the given URL.
      #
      # @param url [String] URL to navigate the page to.
      # @param referrer [String] Referrer URL.
      # @param transition_type [Transitiontype] Intended transition type.
      # @param frame_id [Frameid] Frame id to navigate, if not specified navigates the top frame.
      #
      def navigate(url:, referrer: nil, transition_type: nil, frame_id: nil)
        {
          method: "Page.navigate",
          params: { url: url, referrer: referrer, transitionType: transition_type, frameId: frame_id }.compact
        }
      end

      # Navigates current page to the given history entry.
      #
      # @param entry_id [Integer] Unique id of the entry to navigate to.
      #
      def navigate_to_history_entry(entry_id:)
        {
          method: "Page.navigateToHistoryEntry",
          params: { entryId: entry_id }.compact
        }
      end

      # Print page as PDF.
      #
      # @param landscape [Boolean] Paper orientation. Defaults to false.
      # @param display_header_footer [Boolean] Display header and footer. Defaults to false.
      # @param print_background [Boolean] Print background graphics. Defaults to false.
      # @param scale [Number] Scale of the webpage rendering. Defaults to 1.
      # @param paper_width [Number] Paper width in inches. Defaults to 8.5 inches.
      # @param paper_height [Number] Paper height in inches. Defaults to 11 inches.
      # @param margin_top [Number] Top margin in inches. Defaults to 1cm (~0.4 inches).
      # @param margin_bottom [Number] Bottom margin in inches. Defaults to 1cm (~0.4 inches).
      # @param margin_left [Number] Left margin in inches. Defaults to 1cm (~0.4 inches).
      # @param margin_right [Number] Right margin in inches. Defaults to 1cm (~0.4 inches).
      # @param page_ranges [String] Paper ranges to print, e.g., '1-5, 8, 11-13'. Defaults to the empty string, which means print all pages.
      # @param ignore_invalid_page_ranges [Boolean] Whether to silently ignore invalid but successfully parsed page ranges, such as '3-2'. Defaults to false.
      # @param header_template [String] HTML template for the print header. Should be valid HTML markup with following classes used to inject printing values into them: - `date`: formatted print date - `title`: document title - `url`: document location - `pageNumber`: current page number - `totalPages`: total pages in the document For example, `<span class=title></span>` would generate span containing the title.
      # @param footer_template [String] HTML template for the print footer. Should use the same format as the `headerTemplate`.
      # @param prefer_css_page_size [Boolean] Whether or not to prefer page size as defined by css. Defaults to false, in which case the content will be scaled to fit the paper size.
      #
      def print_to_pdf(landscape: nil, display_header_footer: nil, print_background: nil, scale: nil, paper_width: nil, paper_height: nil, margin_top: nil, margin_bottom: nil, margin_left: nil, margin_right: nil, page_ranges: nil, ignore_invalid_page_ranges: nil, header_template: nil, footer_template: nil, prefer_css_page_size: nil)
        {
          method: "Page.printToPDF",
          params: { landscape: landscape, displayHeaderFooter: display_header_footer, printBackground: print_background, scale: scale, paperWidth: paper_width, paperHeight: paper_height, marginTop: margin_top, marginBottom: margin_bottom, marginLeft: margin_left, marginRight: margin_right, pageRanges: page_ranges, ignoreInvalidPageRanges: ignore_invalid_page_ranges, headerTemplate: header_template, footerTemplate: footer_template, preferCSSPageSize: prefer_css_page_size }.compact
        }
      end

      # Reloads given page optionally ignoring the cache.
      #
      # @param ignore_cache [Boolean] If true, browser cache is ignored (as if the user pressed Shift+refresh).
      # @param script_to_evaluate_on_load [String] If set, the script will be injected into all frames of the inspected page after reload. Argument will be ignored if reloading dataURL origin.
      #
      def reload(ignore_cache: nil, script_to_evaluate_on_load: nil)
        {
          method: "Page.reload",
          params: { ignoreCache: ignore_cache, scriptToEvaluateOnLoad: script_to_evaluate_on_load }.compact
        }
      end

      # Deprecated, please use removeScriptToEvaluateOnNewDocument instead.
      #
      #
      def remove_script_to_evaluate_on_load(identifier:)
        {
          method: "Page.removeScriptToEvaluateOnLoad",
          params: { identifier: identifier }.compact
        }
      end

      # Removes given script from the list.
      #
      #
      def remove_script_to_evaluate_on_new_document(identifier:)
        {
          method: "Page.removeScriptToEvaluateOnNewDocument",
          params: { identifier: identifier }.compact
        }
      end

      # Acknowledges that a screencast frame has been received by the frontend.
      #
      # @param session_id [Integer] Frame number.
      #
      def screencast_frame_ack(session_id:)
        {
          method: "Page.screencastFrameAck",
          params: { sessionId: session_id }.compact
        }
      end

      # Searches for given string in resource content.
      #
      # @param frame_id [Frameid] Frame id for resource to search in.
      # @param url [String] URL of the resource to search in.
      # @param query [String] String to search for.
      # @param case_sensitive [Boolean] If true, search is case sensitive.
      # @param is_regex [Boolean] If true, treats string parameter as regex.
      #
      def search_in_resource(frame_id:, url:, query:, case_sensitive: nil, is_regex: nil)
        {
          method: "Page.searchInResource",
          params: { frameId: frame_id, url: url, query: query, caseSensitive: case_sensitive, isRegex: is_regex }.compact
        }
      end

      # Enable Chrome's experimental ad filter on all sites.
      #
      # @param enabled [Boolean] Whether to block ads.
      #
      def set_ad_blocking_enabled(enabled:)
        {
          method: "Page.setAdBlockingEnabled",
          params: { enabled: enabled }.compact
        }
      end

      # Enable page Content Security Policy by-passing.
      #
      # @param enabled [Boolean] Whether to bypass page CSP.
      #
      def set_bypass_csp(enabled:)
        {
          method: "Page.setBypassCSP",
          params: { enabled: enabled }.compact
        }
      end

      # Overrides the values of device screen dimensions (window.screen.width, window.screen.height,
      # window.innerWidth, window.innerHeight, and "device-width"/"device-height"-related CSS media
      # query results).
      #
      # @param width [Integer] Overriding width value in pixels (minimum 0, maximum 10000000). 0 disables the override.
      # @param height [Integer] Overriding height value in pixels (minimum 0, maximum 10000000). 0 disables the override.
      # @param device_scale_factor [Number] Overriding device scale factor value. 0 disables the override.
      # @param mobile [Boolean] Whether to emulate mobile device. This includes viewport meta tag, overlay scrollbars, text autosizing and more.
      # @param scale [Number] Scale to apply to resulting view image.
      # @param screen_width [Integer] Overriding screen width value in pixels (minimum 0, maximum 10000000).
      # @param screen_height [Integer] Overriding screen height value in pixels (minimum 0, maximum 10000000).
      # @param position_x [Integer] Overriding view X position on screen in pixels (minimum 0, maximum 10000000).
      # @param position_y [Integer] Overriding view Y position on screen in pixels (minimum 0, maximum 10000000).
      # @param dont_set_visible_size [Boolean] Do not set visible view size, rely upon explicit setVisibleSize call.
      # @param screen_orientation [Emulation.screenorientation] Screen orientation override.
      # @param viewport [Viewport] The viewport dimensions and scale. If not set, the override is cleared.
      #
      def set_device_metrics_override(width:, height:, device_scale_factor:, mobile:, scale: nil, screen_width: nil, screen_height: nil, position_x: nil, position_y: nil, dont_set_visible_size: nil, screen_orientation: nil, viewport: nil)
        {
          method: "Page.setDeviceMetricsOverride",
          params: { width: width, height: height, deviceScaleFactor: device_scale_factor, mobile: mobile, scale: scale, screenWidth: screen_width, screenHeight: screen_height, positionX: position_x, positionY: position_y, dontSetVisibleSize: dont_set_visible_size, screenOrientation: screen_orientation, viewport: viewport }.compact
        }
      end

      # Overrides the Device Orientation.
      #
      # @param alpha [Number] Mock alpha
      # @param beta [Number] Mock beta
      # @param gamma [Number] Mock gamma
      #
      def set_device_orientation_override(alpha:, beta:, gamma:)
        {
          method: "Page.setDeviceOrientationOverride",
          params: { alpha: alpha, beta: beta, gamma: gamma }.compact
        }
      end

      # Set generic font families.
      #
      # @param font_families [Fontfamilies] Specifies font families to set. If a font family is not specified, it won't be changed.
      #
      def set_font_families(font_families:)
        {
          method: "Page.setFontFamilies",
          params: { fontFamilies: font_families }.compact
        }
      end

      # Set default font sizes.
      #
      # @param font_sizes [Fontsizes] Specifies font sizes to set. If a font size is not specified, it won't be changed.
      #
      def set_font_sizes(font_sizes:)
        {
          method: "Page.setFontSizes",
          params: { fontSizes: font_sizes }.compact
        }
      end

      # Sets given markup as the document's HTML.
      #
      # @param frame_id [Frameid] Frame id to set HTML for.
      # @param html [String] HTML content to set.
      #
      def set_document_content(frame_id:, html:)
        {
          method: "Page.setDocumentContent",
          params: { frameId: frame_id, html: html }.compact
        }
      end

      # Set the behavior when downloading a file.
      #
      # @param behavior [String] Whether to allow all or deny all download requests, or use default Chrome behavior if available (otherwise deny).
      # @param download_path [String] The default path to save downloaded files to. This is requred if behavior is set to 'allow'
      #
      def set_download_behavior(behavior:, download_path: nil)
        {
          method: "Page.setDownloadBehavior",
          params: { behavior: behavior, downloadPath: download_path }.compact
        }
      end

      # Overrides the Geolocation Position or Error. Omitting any of the parameters emulates position
      # unavailable.
      #
      # @param latitude [Number] Mock latitude
      # @param longitude [Number] Mock longitude
      # @param accuracy [Number] Mock accuracy
      #
      def set_geolocation_override(latitude: nil, longitude: nil, accuracy: nil)
        {
          method: "Page.setGeolocationOverride",
          params: { latitude: latitude, longitude: longitude, accuracy: accuracy }.compact
        }
      end

      # Controls whether page will emit lifecycle events.
      #
      # @param enabled [Boolean] If true, starts emitting lifecycle events.
      #
      def set_lifecycle_events_enabled(enabled:)
        {
          method: "Page.setLifecycleEventsEnabled",
          params: { enabled: enabled }.compact
        }
      end

      # Toggles mouse event-based touch event emulation.
      #
      # @param enabled [Boolean] Whether the touch event emulation should be enabled.
      # @param configuration [String] Touch/gesture events configuration. Default: current platform.
      #
      def set_touch_emulation_enabled(enabled:, configuration: nil)
        {
          method: "Page.setTouchEmulationEnabled",
          params: { enabled: enabled, configuration: configuration }.compact
        }
      end

      # Starts sending each frame using the `screencastFrame` event.
      #
      # @param format [String] Image compression format.
      # @param quality [Integer] Compression quality from range [0..100].
      # @param max_width [Integer] Maximum screenshot width.
      # @param max_height [Integer] Maximum screenshot height.
      # @param every_nth_frame [Integer] Send every n-th frame.
      #
      def start_screencast(format: nil, quality: nil, max_width: nil, max_height: nil, every_nth_frame: nil)
        {
          method: "Page.startScreencast",
          params: { format: format, quality: quality, maxWidth: max_width, maxHeight: max_height, everyNthFrame: every_nth_frame }.compact
        }
      end

      # Force the page stop all navigations and pending resource fetches.
      #
      #
      def stop_loading
        {
          method: "Page.stopLoading"
        }
      end

      # Crashes renderer on the IO thread, generates minidumps.
      #
      #
      def crash
        {
          method: "Page.crash"
        }
      end

      # Tries to close page, running its beforeunload hooks, if any.
      #
      #
      def close
        {
          method: "Page.close"
        }
      end

      # Tries to update the web lifecycle state of the page.
      # It will transition the page to the given state according to:
      # https://github.com/WICG/web-lifecycle/
      #
      # @param state [String] Target lifecycle state
      #
      def set_web_lifecycle_state(state:)
        {
          method: "Page.setWebLifecycleState",
          params: { state: state }.compact
        }
      end

      # Stops sending each frame in the `screencastFrame`.
      #
      #
      def stop_screencast
        {
          method: "Page.stopScreencast"
        }
      end

      # Forces compilation cache to be generated for every subresource script.
      #
      #
      def set_produce_compilation_cache(enabled:)
        {
          method: "Page.setProduceCompilationCache",
          params: { enabled: enabled }.compact
        }
      end

      # Seeds compilation cache for given url. Compilation cache does not survive
      # cross-process navigation.
      #
      # @param data [Binary] Base64-encoded data
      #
      def add_compilation_cache(url:, data:)
        {
          method: "Page.addCompilationCache",
          params: { url: url, data: data }.compact
        }
      end

      # Clears seeded compilation cache.
      #
      #
      def clear_compilation_cache
        {
          method: "Page.clearCompilationCache"
        }
      end

      # Generates a report for testing.
      #
      # @param message [String] Message to be displayed in the report.
      # @param group [String] Specifies the endpoint group to deliver the report to.
      #
      def generate_test_report(message:, group: nil)
        {
          method: "Page.generateTestReport",
          params: { message: message, group: group }.compact
        }
      end

      # Pauses page execution. Can be resumed using generic Runtime.runIfWaitingForDebugger.
      #
      #
      def wait_for_debugger
        {
          method: "Page.waitForDebugger"
        }
      end
    end
  end
end
