module Chromiebara
  module Protocol
    module DOMDebugger
      extend self

      # Returns event listeners of the given object.
      #
      # @param object_id [Runtime.remoteobjectid] Identifier of the object to return listeners for.
      # @param depth [Integer] The maximum depth at which Node children should be retrieved, defaults to 1. Use -1 for the entire subtree or provide an integer larger than 0.
      # @param pierce [Boolean] Whether or not iframes and shadow roots should be traversed when returning the subtree (default is false). Reports listeners for all contexts if pierce is enabled.
      #
      def get_event_listeners(object_id:, depth: nil, pierce: nil)
        {
          method: "DOMDebugger.getEventListeners",
          params: { objectId: object_id, depth: depth, pierce: pierce }.compact
        }
      end

      # Removes DOM breakpoint that was set using `setDOMBreakpoint`.
      #
      # @param node_id [Dom.nodeid] Identifier of the node to remove breakpoint from.
      # @param type [Dombreakpointtype] Type of the breakpoint to remove.
      #
      def remove_dom_breakpoint(node_id:, type:)
        {
          method: "DOMDebugger.removeDOMBreakpoint",
          params: { nodeId: node_id, type: type }.compact
        }
      end

      # Removes breakpoint on particular DOM event.
      #
      # @param event_name [String] Event name.
      # @param target_name [String] EventTarget interface name.
      #
      def remove_event_listener_breakpoint(event_name:, target_name: nil)
        {
          method: "DOMDebugger.removeEventListenerBreakpoint",
          params: { eventName: event_name, targetName: target_name }.compact
        }
      end

      # Removes breakpoint on particular native event.
      #
      # @param event_name [String] Instrumentation name to stop on.
      #
      def remove_instrumentation_breakpoint(event_name:)
        {
          method: "DOMDebugger.removeInstrumentationBreakpoint",
          params: { eventName: event_name }.compact
        }
      end

      # Removes breakpoint from XMLHttpRequest.
      #
      # @param url [String] Resource URL substring.
      #
      def remove_xhr_breakpoint(url:)
        {
          method: "DOMDebugger.removeXHRBreakpoint",
          params: { url: url }.compact
        }
      end

      # Sets breakpoint on particular operation with DOM.
      #
      # @param node_id [Dom.nodeid] Identifier of the node to set breakpoint on.
      # @param type [Dombreakpointtype] Type of the operation to stop upon.
      #
      def set_dom_breakpoint(node_id:, type:)
        {
          method: "DOMDebugger.setDOMBreakpoint",
          params: { nodeId: node_id, type: type }.compact
        }
      end

      # Sets breakpoint on particular DOM event.
      #
      # @param event_name [String] DOM Event name to stop on (any DOM event will do).
      # @param target_name [String] EventTarget interface name to stop on. If equal to `"*"` or not provided, will stop on any EventTarget.
      #
      def set_event_listener_breakpoint(event_name:, target_name: nil)
        {
          method: "DOMDebugger.setEventListenerBreakpoint",
          params: { eventName: event_name, targetName: target_name }.compact
        }
      end

      # Sets breakpoint on particular native event.
      #
      # @param event_name [String] Instrumentation name to stop on.
      #
      def set_instrumentation_breakpoint(event_name:)
        {
          method: "DOMDebugger.setInstrumentationBreakpoint",
          params: { eventName: event_name }.compact
        }
      end

      # Sets breakpoint on XMLHttpRequest.
      #
      # @param url [String] Resource URL substring. All XHRs having this substring in the URL will get stopped upon.
      #
      def set_xhr_breakpoint(url:)
        {
          method: "DOMDebugger.setXHRBreakpoint",
          params: { url: url }.compact
        }
      end
    end
  end
end
