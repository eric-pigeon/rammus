module Rammus
  module Protocol
    module CSS
      extend self

      # Inserts a new rule with the given `ruleText` in a stylesheet with given `styleSheetId`, at the
      # position specified by `location`.
      #
      # @param style_sheet_id [Stylesheetid] The css style sheet identifier where a new rule should be inserted.
      # @param rule_text [String] The text of a new rule.
      # @param location [Sourcerange] Text position of a new rule in the target style sheet.
      #
      def add_rule(style_sheet_id:, rule_text:, location:)
        {
          method: "CSS.addRule",
          params: { styleSheetId: style_sheet_id, ruleText: rule_text, location: location }.compact
        }
      end

      # Returns all class names from specified stylesheet.
      #
      def collect_class_names(style_sheet_id:)
        {
          method: "CSS.collectClassNames",
          params: { styleSheetId: style_sheet_id }.compact
        }
      end

      # Creates a new special "via-inspector" stylesheet in the frame with given `frameId`.
      #
      # @param frame_id [Page.frameid] Identifier of the frame where "via-inspector" stylesheet should be created.
      #
      def create_style_sheet(frame_id:)
        {
          method: "CSS.createStyleSheet",
          params: { frameId: frame_id }.compact
        }
      end

      # Disables the CSS agent for the given page.
      #
      def disable
        {
          method: "CSS.disable"
        }
      end

      # Enables the CSS agent for the given page. Clients should not assume that the CSS agent has been
      # enabled until the result of this command is received.
      #
      def enable
        {
          method: "CSS.enable"
        }
      end

      # Ensures that the given node will have specified pseudo-classes whenever its style is computed by
      # the browser.
      #
      # @param node_id [Dom.nodeid] The element id for which to force the pseudo state.
      # @param forced_pseudo_classes [Array] Element pseudo classes to force when computing the element's style.
      #
      def force_pseudo_state(node_id:, forced_pseudo_classes:)
        {
          method: "CSS.forcePseudoState",
          params: { nodeId: node_id, forcedPseudoClasses: forced_pseudo_classes }.compact
        }
      end

      # @param node_id [Dom.nodeid] Id of the node to get background colors for.
      #
      def get_background_colors(node_id:)
        {
          method: "CSS.getBackgroundColors",
          params: { nodeId: node_id }.compact
        }
      end

      # Returns the computed style for a DOM node identified by `nodeId`.
      #
      def get_computed_style_for_node(node_id:)
        {
          method: "CSS.getComputedStyleForNode",
          params: { nodeId: node_id }.compact
        }
      end

      # Returns the styles defined inline (explicitly in the "style" attribute and implicitly, using DOM
      # attributes) for a DOM node identified by `nodeId`.
      #
      def get_inline_styles_for_node(node_id:)
        {
          method: "CSS.getInlineStylesForNode",
          params: { nodeId: node_id }.compact
        }
      end

      # Returns requested styles for a DOM node identified by `nodeId`.
      #
      def get_matched_styles_for_node(node_id:)
        {
          method: "CSS.getMatchedStylesForNode",
          params: { nodeId: node_id }.compact
        }
      end

      # Returns all media queries parsed by the rendering engine.
      #
      def get_media_queries
        {
          method: "CSS.getMediaQueries"
        }
      end

      # Requests information about platform fonts which we used to render child TextNodes in the given
      # node.
      #
      def get_platform_fonts_for_node(node_id:)
        {
          method: "CSS.getPlatformFontsForNode",
          params: { nodeId: node_id }.compact
        }
      end

      # Returns the current textual content for a stylesheet.
      #
      def get_style_sheet_text(style_sheet_id:)
        {
          method: "CSS.getStyleSheetText",
          params: { styleSheetId: style_sheet_id }.compact
        }
      end

      # Find a rule with the given active property for the given node and set the new value for this
      # property
      #
      # @param node_id [Dom.nodeid] The element id for which to set property.
      #
      def set_effective_property_value_for_node(node_id:, property_name:, value:)
        {
          method: "CSS.setEffectivePropertyValueForNode",
          params: { nodeId: node_id, propertyName: property_name, value: value }.compact
        }
      end

      # Modifies the keyframe rule key text.
      #
      def set_keyframe_key(style_sheet_id:, range:, key_text:)
        {
          method: "CSS.setKeyframeKey",
          params: { styleSheetId: style_sheet_id, range: range, keyText: key_text }.compact
        }
      end

      # Modifies the rule selector.
      #
      def set_media_text(style_sheet_id:, range:, text:)
        {
          method: "CSS.setMediaText",
          params: { styleSheetId: style_sheet_id, range: range, text: text }.compact
        }
      end

      # Modifies the rule selector.
      #
      def set_rule_selector(style_sheet_id:, range:, selector:)
        {
          method: "CSS.setRuleSelector",
          params: { styleSheetId: style_sheet_id, range: range, selector: selector }.compact
        }
      end

      # Sets the new stylesheet text.
      #
      def set_style_sheet_text(style_sheet_id:, text:)
        {
          method: "CSS.setStyleSheetText",
          params: { styleSheetId: style_sheet_id, text: text }.compact
        }
      end

      # Applies specified style edits one after another in the given order.
      #
      def set_style_texts(edits:)
        {
          method: "CSS.setStyleTexts",
          params: { edits: edits }.compact
        }
      end

      # Enables the selector recording.
      #
      def start_rule_usage_tracking
        {
          method: "CSS.startRuleUsageTracking"
        }
      end

      # Stop tracking rule usage and return the list of rules that were used since last call to
      # `takeCoverageDelta` (or since start of coverage instrumentation)
      #
      def stop_rule_usage_tracking
        {
          method: "CSS.stopRuleUsageTracking"
        }
      end

      # Obtain list of rules that became used since last call to this method (or since start of coverage
      # instrumentation)
      #
      def take_coverage_delta
        {
          method: "CSS.takeCoverageDelta"
        }
      end

      def fonts_updated
        'CSS.fontsUpdated'
      end

      def media_query_result_changed
        'CSS.mediaQueryResultChanged'
      end

      def style_sheet_added
        'CSS.styleSheetAdded'
      end

      def style_sheet_changed
        'CSS.styleSheetChanged'
      end

      def style_sheet_removed
        'CSS.styleSheetRemoved'
      end
    end
  end
end
