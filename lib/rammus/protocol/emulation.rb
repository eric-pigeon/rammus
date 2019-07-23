module Rammus
  module Protocol
    module Emulation
      extend self

      # Tells whether emulation is supported.
      #
      def can_emulate
        {
          method: "Emulation.canEmulate"
        }
      end

      # Clears the overriden device metrics.
      #
      def clear_device_metrics_override
        {
          method: "Emulation.clearDeviceMetricsOverride"
        }
      end

      # Clears the overriden Geolocation Position and Error.
      #
      def clear_geolocation_override
        {
          method: "Emulation.clearGeolocationOverride"
        }
      end

      # Requests that page scale factor is reset to initial values.
      #
      def reset_page_scale_factor
        {
          method: "Emulation.resetPageScaleFactor"
        }
      end

      # Enables or disables simulating a focused and active page.
      #
      # @param enabled [Boolean] Whether to enable to disable focus emulation.
      #
      def set_focus_emulation_enabled(enabled:)
        {
          method: "Emulation.setFocusEmulationEnabled",
          params: { enabled: enabled }.compact
        }
      end

      # Enables CPU throttling to emulate slow CPUs.
      #
      # @param rate [Number] Throttling rate as a slowdown factor (1 is no throttle, 2 is 2x slowdown, etc).
      #
      def set_cpu_throttling_rate(rate:)
        {
          method: "Emulation.setCPUThrottlingRate",
          params: { rate: rate }.compact
        }
      end

      # Sets or clears an override of the default background color of the frame. This override is used
      # if the content does not specify one.
      #
      # @param color [Dom.rgba] RGBA of the default background color. If not specified, any existing override will be cleared.
      #
      def set_default_background_color_override(color: nil)
        {
          method: "Emulation.setDefaultBackgroundColorOverride",
          params: { color: color }.compact
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
      # @param screen_orientation [Screenorientation] Screen orientation override.
      # @param viewport [Page.viewport] If set, the visible area of the page will be overridden to this viewport. This viewport change is not observed by the page, e.g. viewport-relative elements do not change positions.
      #
      def set_device_metrics_override(width:, height:, device_scale_factor:, mobile:, scale: nil, screen_width: nil, screen_height: nil, position_x: nil, position_y: nil, dont_set_visible_size: nil, screen_orientation: nil, viewport: nil)
        {
          method: "Emulation.setDeviceMetricsOverride",
          params: { width: width, height: height, deviceScaleFactor: device_scale_factor, mobile: mobile, scale: scale, screenWidth: screen_width, screenHeight: screen_height, positionX: position_x, positionY: position_y, dontSetVisibleSize: dont_set_visible_size, screenOrientation: screen_orientation, viewport: viewport }.compact
        }
      end

      # @param hidden [Boolean] Whether scrollbars should be always hidden.
      #
      def set_scrollbars_hidden(hidden:)
        {
          method: "Emulation.setScrollbarsHidden",
          params: { hidden: hidden }.compact
        }
      end

      # @param disabled [Boolean] Whether document.coookie API should be disabled.
      #
      def set_document_cookie_disabled(disabled:)
        {
          method: "Emulation.setDocumentCookieDisabled",
          params: { disabled: disabled }.compact
        }
      end

      # @param enabled [Boolean] Whether touch emulation based on mouse input should be enabled.
      # @param configuration [String] Touch/gesture events configuration. Default: current platform.
      #
      def set_emit_touch_events_for_mouse(enabled:, configuration: nil)
        {
          method: "Emulation.setEmitTouchEventsForMouse",
          params: { enabled: enabled, configuration: configuration }.compact
        }
      end

      # Emulates the given media for CSS media queries.
      #
      # @param media [String] Media type to emulate. Empty string disables the override.
      #
      def set_emulated_media(media:)
        {
          method: "Emulation.setEmulatedMedia",
          params: { media: media }.compact
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
          method: "Emulation.setGeolocationOverride",
          params: { latitude: latitude, longitude: longitude, accuracy: accuracy }.compact
        }
      end

      # Overrides value returned by the javascript navigator object.
      #
      # @param platform [String] The platform navigator.platform should return.
      #
      def set_navigator_overrides(platform:)
        {
          method: "Emulation.setNavigatorOverrides",
          params: { platform: platform }.compact
        }
      end

      # Sets a specified page scale factor.
      #
      # @param page_scale_factor [Number] Page scale factor.
      #
      def set_page_scale_factor(page_scale_factor:)
        {
          method: "Emulation.setPageScaleFactor",
          params: { pageScaleFactor: page_scale_factor }.compact
        }
      end

      # Switches script execution in the page.
      #
      # @param value [Boolean] Whether script execution should be disabled in the page.
      #
      def set_script_execution_disabled(value:)
        {
          method: "Emulation.setScriptExecutionDisabled",
          params: { value: value }.compact
        }
      end

      # Enables touch on platforms which do not support them.
      #
      # @param enabled [Boolean] Whether the touch event emulation should be enabled.
      # @param max_touch_points [Integer] Maximum touch points supported. Defaults to one.
      #
      def set_touch_emulation_enabled(enabled:, max_touch_points: nil)
        {
          method: "Emulation.setTouchEmulationEnabled",
          params: { enabled: enabled, maxTouchPoints: max_touch_points }.compact
        }
      end

      # Turns on virtual time for all frames (replacing real-time with a synthetic time source) and sets
      # the current virtual time policy.  Note this supersedes any previous time budget.
      #
      # @param budget [Number] If set, after this many virtual milliseconds have elapsed virtual time will be paused and a virtualTimeBudgetExpired event is sent.
      # @param max_virtual_time_task_starvation_count [Integer] If set this specifies the maximum number of tasks that can be run before virtual is forced forwards to prevent deadlock.
      # @param wait_for_navigation [Boolean] If set the virtual time policy change should be deferred until any frame starts navigating. Note any previous deferred policy change is superseded.
      # @param initial_virtual_time [Network.timesinceepoch] If set, base::Time::Now will be overriden to initially return this value.
      #
      def set_virtual_time_policy(policy:, budget: nil, max_virtual_time_task_starvation_count: nil, wait_for_navigation: nil, initial_virtual_time: nil)
        {
          method: "Emulation.setVirtualTimePolicy",
          params: { policy: policy, budget: budget, maxVirtualTimeTaskStarvationCount: max_virtual_time_task_starvation_count, waitForNavigation: wait_for_navigation, initialVirtualTime: initial_virtual_time }.compact
        }
      end

      # Resizes the frame/viewport of the page. Note that this does not affect the frame's container
      # (e.g. browser window). Can be used to produce screenshots of the specified size. Not supported
      # on Android.
      #
      # @param width [Integer] Frame width (DIP).
      # @param height [Integer] Frame height (DIP).
      #
      def set_visible_size(width:, height:)
        {
          method: "Emulation.setVisibleSize",
          params: { width: width, height: height }.compact
        }
      end

      # Allows overriding user agent with the given string.
      #
      # @param user_agent [String] User agent to use.
      # @param accept_language [String] Browser langugage to emulate.
      # @param platform [String] The platform navigator.platform should return.
      #
      def set_user_agent_override(user_agent:, accept_language: nil, platform: nil)
        {
          method: "Emulation.setUserAgentOverride",
          params: { userAgent: user_agent, acceptLanguage: accept_language, platform: platform }.compact
        }
      end

      def virtual_time_advanced
        'Emulation.virtualTimeAdvanced'
      end

      def virtual_time_budget_expired
        'Emulation.virtualTimeBudgetExpired'
      end

      def virtual_time_paused
        'Emulation.virtualTimePaused'
      end
    end
  end
end
