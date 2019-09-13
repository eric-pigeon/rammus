module Rammus
  module Protocol
    module Target
      extend self

      # Activates (focuses) the target.
      #
      def activate_target(target_id:)
        {
          method: "Target.activateTarget",
          params: { targetId: target_id }.compact
        }
      end

      # Attaches to the target with given id.
      #
      # @param flatten [Boolean] Enables "flat" access to the session via specifying sessionId attribute in the commands.
      #
      def attach_to_target(target_id:, flatten: nil)
        {
          method: "Target.attachToTarget",
          params: { targetId: target_id, flatten: flatten }.compact
        }
      end

      # Attaches to the browser target, only uses flat sessionId mode.
      #
      def attach_to_browser_target
        {
          method: "Target.attachToBrowserTarget"
        }
      end

      # Closes the target. If the target is a page that gets closed too.
      #
      def close_target(target_id:)
        {
          method: "Target.closeTarget",
          params: { targetId: target_id }.compact
        }
      end

      # Inject object to the target's main frame that provides a communication
      # channel with browser target.
      # 
      # Injected object will be available as `window[bindingName]`.
      # 
      # The object has the follwing API:
      # - `binding.send(json)` - a method to send messages over the remote debugging protocol
      # - `binding.onmessage = json => handleMessage(json)` - a callback that will be called for the protocol notifications and command responses.
      #
      # @param binding_name [String] Binding name, 'cdp' if not specified.
      #
      def expose_dev_tools_protocol(target_id:, binding_name: nil)
        {
          method: "Target.exposeDevToolsProtocol",
          params: { targetId: target_id, bindingName: binding_name }.compact
        }
      end

      # Creates a new empty BrowserContext. Similar to an incognito profile but you can have more than
      # one.
      #
      def create_browser_context
        {
          method: "Target.createBrowserContext"
        }
      end

      # Returns all browser contexts created with `Target.createBrowserContext` method.
      #
      def get_browser_contexts
        {
          method: "Target.getBrowserContexts"
        }
      end

      # Creates a new page.
      #
      # @param url [String] The initial URL the page will be navigated to.
      # @param width [Integer] Frame width in DIP (headless chrome only).
      # @param height [Integer] Frame height in DIP (headless chrome only).
      # @param browser_context_id [Browsercontextid] The browser context to create the page in.
      # @param enable_begin_frame_control [Boolean] Whether BeginFrames for this target will be controlled via DevTools (headless chrome only, not supported on MacOS yet, false by default).
      # @param new_window [Boolean] Whether to create a new Window or Tab (chrome-only, false by default).
      # @param background [Boolean] Whether to create the target in background or foreground (chrome-only, false by default).
      #
      def create_target(url:, width: nil, height: nil, browser_context_id: nil, enable_begin_frame_control: nil, new_window: nil, background: nil)
        {
          method: "Target.createTarget",
          params: { url: url, width: width, height: height, browserContextId: browser_context_id, enableBeginFrameControl: enable_begin_frame_control, newWindow: new_window, background: background }.compact
        }
      end

      # Detaches session with given id.
      #
      # @param session_id [Sessionid] Session to detach.
      # @param target_id [Targetid] Deprecated.
      #
      def detach_from_target(session_id: nil, target_id: nil)
        {
          method: "Target.detachFromTarget",
          params: { sessionId: session_id, targetId: target_id }.compact
        }
      end

      # Deletes a BrowserContext. All the belonging pages will be closed without calling their
      # beforeunload hooks.
      #
      def dispose_browser_context(browser_context_id:)
        {
          method: "Target.disposeBrowserContext",
          params: { browserContextId: browser_context_id }.compact
        }
      end

      # Returns information about a target.
      #
      def get_target_info(target_id: nil)
        {
          method: "Target.getTargetInfo",
          params: { targetId: target_id }.compact
        }
      end

      # Retrieves a list of available targets.
      #
      def get_targets
        {
          method: "Target.getTargets"
        }
      end

      # Sends protocol message over session with given id.
      #
      # @param session_id [Sessionid] Identifier of the session.
      # @param target_id [Targetid] Deprecated.
      #
      def send_message_to_target(message:, session_id: nil, target_id: nil)
        {
          method: "Target.sendMessageToTarget",
          params: { message: message, sessionId: session_id, targetId: target_id }.compact
        }
      end

      # Controls whether to automatically attach to new targets which are considered to be related to
      # this one. When turned on, attaches to all existing related targets as well. When turned off,
      # automatically detaches from all currently attached targets.
      #
      # @param auto_attach [Boolean] Whether to auto-attach to related targets.
      # @param wait_for_debugger_on_start [Boolean] Whether to pause new targets when attaching to them. Use `Runtime.runIfWaitingForDebugger` to run paused targets.
      # @param flatten [Boolean] Enables "flat" access to the session via specifying sessionId attribute in the commands.
      #
      def set_auto_attach(auto_attach:, wait_for_debugger_on_start:, flatten: nil)
        {
          method: "Target.setAutoAttach",
          params: { autoAttach: auto_attach, waitForDebuggerOnStart: wait_for_debugger_on_start, flatten: flatten }.compact
        }
      end

      # Controls whether to discover available targets and notify via
      # `targetCreated/targetInfoChanged/targetDestroyed` events.
      #
      # @param discover [Boolean] Whether to discover available targets.
      #
      def set_discover_targets(discover:)
        {
          method: "Target.setDiscoverTargets",
          params: { discover: discover }.compact
        }
      end

      # Enables target discovery for the specified locations, when `setDiscoverTargets` was set to
      # `true`.
      #
      # @param locations [Array] List of remote locations.
      #
      def set_remote_locations(locations:)
        {
          method: "Target.setRemoteLocations",
          params: { locations: locations }.compact
        }
      end

      def attached_to_target
        'Target.attachedToTarget'
      end

      def detached_from_target
        'Target.detachedFromTarget'
      end

      def received_message_from_target
        'Target.receivedMessageFromTarget'
      end

      def target_created
        'Target.targetCreated'
      end

      def target_destroyed
        'Target.targetDestroyed'
      end

      def target_crashed
        'Target.targetCrashed'
      end

      def target_info_changed
        'Target.targetInfoChanged'
      end
    end
  end
end
