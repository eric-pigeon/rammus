module Rammus
  module Protocol
    module Overlay
      extend self

      # Disables domain notifications.
      #
      def disable
        {
          method: "Overlay.disable"
        }
      end

      # Enables domain notifications.
      #
      def enable
        {
          method: "Overlay.enable"
        }
      end

      # For testing.
      #
      # @param node_id [Dom.nodeid] Id of the node to get highlight object for.
      #
      def get_highlight_object_for_test(node_id:)
        {
          method: "Overlay.getHighlightObjectForTest",
          params: { nodeId: node_id }.compact
        }
      end

      # Hides any highlight.
      #
      def hide_highlight
        {
          method: "Overlay.hideHighlight"
        }
      end

      # Highlights owner element of the frame with given id.
      #
      # @param frame_id [Page.frameid] Identifier of the frame to highlight.
      # @param content_color [Dom.rgba] The content box highlight fill color (default: transparent).
      # @param content_outline_color [Dom.rgba] The content box highlight outline color (default: transparent).
      #
      def highlight_frame(frame_id:, content_color: nil, content_outline_color: nil)
        {
          method: "Overlay.highlightFrame",
          params: { frameId: frame_id, contentColor: content_color, contentOutlineColor: content_outline_color }.compact
        }
      end

      # Highlights DOM node with given id or with the given JavaScript object wrapper. Either nodeId or
      # objectId must be specified.
      #
      # @param highlight_config [Highlightconfig] A descriptor for the highlight appearance.
      # @param node_id [Dom.nodeid] Identifier of the node to highlight.
      # @param backend_node_id [Dom.backendnodeid] Identifier of the backend node to highlight.
      # @param object_id [Runtime.remoteobjectid] JavaScript object id of the node to be highlighted.
      # @param selector [String] Selectors to highlight relevant nodes.
      #
      def highlight_node(highlight_config:, node_id: nil, backend_node_id: nil, object_id: nil, selector: nil)
        {
          method: "Overlay.highlightNode",
          params: { highlightConfig: highlight_config, nodeId: node_id, backendNodeId: backend_node_id, objectId: object_id, selector: selector }.compact
        }
      end

      # Highlights given quad. Coordinates are absolute with respect to the main frame viewport.
      #
      # @param quad [Dom.quad] Quad to highlight
      # @param color [Dom.rgba] The highlight fill color (default: transparent).
      # @param outline_color [Dom.rgba] The highlight outline color (default: transparent).
      #
      def highlight_quad(quad:, color: nil, outline_color: nil)
        {
          method: "Overlay.highlightQuad",
          params: { quad: quad, color: color, outlineColor: outline_color }.compact
        }
      end

      # Highlights given rectangle. Coordinates are absolute with respect to the main frame viewport.
      #
      # @param x [Integer] X coordinate
      # @param y [Integer] Y coordinate
      # @param width [Integer] Rectangle width
      # @param height [Integer] Rectangle height
      # @param color [Dom.rgba] The highlight fill color (default: transparent).
      # @param outline_color [Dom.rgba] The highlight outline color (default: transparent).
      #
      def highlight_rect(x:, y:, width:, height:, color: nil, outline_color: nil)
        {
          method: "Overlay.highlightRect",
          params: { x: x, y: y, width: width, height: height, color: color, outlineColor: outline_color }.compact
        }
      end

      # Enters the 'inspect' mode. In this mode, elements that user is hovering over are highlighted.
      # Backend then generates 'inspectNodeRequested' event upon element selection.
      #
      # @param mode [Inspectmode] Set an inspection mode.
      # @param highlight_config [Highlightconfig] A descriptor for the highlight appearance of hovered-over nodes. May be omitted if `enabled == false`.
      #
      def set_inspect_mode(mode:, highlight_config: nil)
        {
          method: "Overlay.setInspectMode",
          params: { mode: mode, highlightConfig: highlight_config }.compact
        }
      end

      # Highlights owner element of all frames detected to be ads.
      #
      # @param show [Boolean] True for showing ad highlights
      #
      def set_show_ad_highlights(show:)
        {
          method: "Overlay.setShowAdHighlights",
          params: { show: show }.compact
        }
      end

      # @param message [String] The message to display, also triggers resume and step over controls.
      #
      def set_paused_in_debugger_message(message: nil)
        {
          method: "Overlay.setPausedInDebuggerMessage",
          params: { message: message }.compact
        }
      end

      # Requests that backend shows debug borders on layers
      #
      # @param show [Boolean] True for showing debug borders
      #
      def set_show_debug_borders(show:)
        {
          method: "Overlay.setShowDebugBorders",
          params: { show: show }.compact
        }
      end

      # Requests that backend shows the FPS counter
      #
      # @param show [Boolean] True for showing the FPS counter
      #
      def set_show_fps_counter(show:)
        {
          method: "Overlay.setShowFPSCounter",
          params: { show: show }.compact
        }
      end

      # Requests that backend shows paint rectangles
      #
      # @param result [Boolean] True for showing paint rectangles
      #
      def set_show_paint_rects(result:)
        {
          method: "Overlay.setShowPaintRects",
          params: { result: result }.compact
        }
      end

      # Requests that backend shows scroll bottleneck rects
      #
      # @param show [Boolean] True for showing scroll bottleneck rects
      #
      def set_show_scroll_bottleneck_rects(show:)
        {
          method: "Overlay.setShowScrollBottleneckRects",
          params: { show: show }.compact
        }
      end

      # Requests that backend shows hit-test borders on layers
      #
      # @param show [Boolean] True for showing hit-test borders
      #
      def set_show_hit_test_borders(show:)
        {
          method: "Overlay.setShowHitTestBorders",
          params: { show: show }.compact
        }
      end

      # Paints viewport size upon main frame resize.
      #
      # @param show [Boolean] Whether to paint size or not.
      #
      def set_show_viewport_size_on_resize(show:)
        {
          method: "Overlay.setShowViewportSizeOnResize",
          params: { show: show }.compact
        }
      end

      # @param suspended [Boolean] Whether overlay should be suspended and not consume any resources until resumed.
      #
      def set_suspended(suspended:)
        {
          method: "Overlay.setSuspended",
          params: { suspended: suspended }.compact
        }
      end

      def inspect_node_requested
        'Overlay.inspectNodeRequested'
      end

      def node_highlight_requested
        'Overlay.nodeHighlightRequested'
      end

      def screenshot_requested
        'Overlay.screenshotRequested'
      end

      def inspect_mode_canceled
        'Overlay.inspectModeCanceled'
      end
    end
  end
end
