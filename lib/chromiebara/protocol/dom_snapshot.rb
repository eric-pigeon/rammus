module Chromiebara
  module Protocol
    module DOMSnapshot
      extend self

      # Disables DOM snapshot agent for the given page.
      # 
      #
      def disable
        {
          method: "DOMSnapshot.disable"
        }
      end

      # Enables DOM snapshot agent for the given page.
      # 
      #
      def enable
        {
          method: "DOMSnapshot.enable"
        }
      end

      # Returns a document snapshot, including the full DOM tree of the root node (including iframes,
      # template contents, and imported documents) in a flattened array, as well as layout and
      # white-listed computed style information for the nodes. Shadow DOM in the returned DOM tree is
      # flattened.
      # 
      # @param computed_style_whitelist [Array] Whitelist of computed styles to return.
      # @param include_event_listeners [Boolean] Whether or not to retrieve details of DOM listeners (default false).
      # @param include_paint_order [Boolean] Whether to determine and include the paint order index of LayoutTreeNodes (default false).
      # @param include_user_agent_shadow_tree [Boolean] Whether to include UA shadow tree in the snapshot (default false).
      #
      def get_snapshot(computed_style_whitelist:, include_event_listeners: nil, include_paint_order: nil, include_user_agent_shadow_tree: nil)
        {
          method: "DOMSnapshot.getSnapshot",
          params: { computedStyleWhitelist: computed_style_whitelist, includeEventListeners: include_event_listeners, includePaintOrder: include_paint_order, includeUserAgentShadowTree: include_user_agent_shadow_tree }.compact
        }
      end

      # Returns a document snapshot, including the full DOM tree of the root node (including iframes,
      # template contents, and imported documents) in a flattened array, as well as layout and
      # white-listed computed style information for the nodes. Shadow DOM in the returned DOM tree is
      # flattened.
      # 
      # @param computed_styles [Array] Whitelist of computed styles to return.
      #
      def capture_snapshot(computed_styles:)
        {
          method: "DOMSnapshot.captureSnapshot",
          params: { computedStyles: computed_styles }.compact
        }
      end
    end
  end
end
