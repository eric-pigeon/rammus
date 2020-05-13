# frozen_string_literal: true

module Rammus
  module Protocol
    module Browser
      extend self

      # Grant specific permissions to the given origin and reject all others.
      #
      # @param browser_context_id [Target.browsercontextid] BrowserContext to override permissions. When omitted, default browser context is used.
      #
      def grant_permissions(origin:, permissions:, browser_context_id: nil)
        {
          method: "Browser.grantPermissions",
          params: { origin: origin, permissions: permissions, browserContextId: browser_context_id }.compact
        }
      end

      # Reset all permission management for all origins.
      #
      # @param browser_context_id [Target.browsercontextid] BrowserContext to reset permissions. When omitted, default browser context is used.
      #
      def reset_permissions(browser_context_id: nil)
        {
          method: "Browser.resetPermissions",
          params: { browserContextId: browser_context_id }.compact
        }
      end

      # Close browser gracefully.
      #
      def close
        {
          method: "Browser.close"
        }
      end

      # Crashes browser on the main thread.
      #
      def crash
        {
          method: "Browser.crash"
        }
      end

      # Crashes GPU process.
      #
      def crash_gpu_process
        {
          method: "Browser.crashGpuProcess"
        }
      end

      # Returns version information.
      #
      def get_version
        {
          method: "Browser.getVersion"
        }
      end

      # Returns the command line switches for the browser process if, and only if
      # --enable-automation is on the commandline.
      #
      def get_browser_command_line
        {
          method: "Browser.getBrowserCommandLine"
        }
      end

      # Get Chrome histograms.
      #
      # @param query [String] Requested substring in name. Only histograms which have query as a substring in their name are extracted. An empty or absent query returns all histograms.
      # @param delta [Boolean] If true, retrieve delta since last call.
      #
      def get_histograms(query: nil, delta: nil)
        {
          method: "Browser.getHistograms",
          params: { query: query, delta: delta }.compact
        }
      end

      # Get a Chrome histogram by name.
      #
      # @param name [String] Requested histogram name.
      # @param delta [Boolean] If true, retrieve delta since last call.
      #
      def get_histogram(name:, delta: nil)
        {
          method: "Browser.getHistogram",
          params: { name: name, delta: delta }.compact
        }
      end

      # Get position and size of the browser window.
      #
      # @param window_id [Windowid] Browser window id.
      #
      def get_window_bounds(window_id:)
        {
          method: "Browser.getWindowBounds",
          params: { windowId: window_id }.compact
        }
      end

      # Get the browser window that contains the devtools target.
      #
      # @param target_id [Target.targetid] Devtools agent host id. If called as a part of the session, associated targetId is used.
      #
      def get_window_for_target(target_id: nil)
        {
          method: "Browser.getWindowForTarget",
          params: { targetId: target_id }.compact
        }
      end

      # Set position and/or size of the browser window.
      #
      # @param window_id [Windowid] Browser window id.
      # @param bounds [Bounds] New window bounds. The 'minimized', 'maximized' and 'fullscreen' states cannot be combined with 'left', 'top', 'width' or 'height'. Leaves unspecified fields unchanged.
      #
      def set_window_bounds(window_id:, bounds:)
        {
          method: "Browser.setWindowBounds",
          params: { windowId: window_id, bounds: bounds }.compact
        }
      end

      # Set dock tile details, platform-specific.
      #
      # @param image [Binary] Png encoded image.
      #
      def set_dock_tile(badge_label: nil, image: nil)
        {
          method: "Browser.setDockTile",
          params: { badgeLabel: badge_label, image: image }.compact
        }
      end
    end
  end
end
