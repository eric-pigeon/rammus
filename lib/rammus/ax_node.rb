module Rammus
  # @!visibility private
  class AXNode
    def self.create_tree(payloads)
      node_by_id = payloads.each_with_object({}) do |payload, memo|
        memo[payload["nodeId"]] = AXNode.new payload;
      end

      node_by_id.values.each do |node|
        node.payload.fetch("childIds", []).each do |child_id|
          node.children.push node_by_id[child_id]
        end
      end

      node_by_id.values.first
    end

    attr_reader :payload, :children, :focusable

    def initialize(payload)
      @payload = payload

      # @type {!Array<!AXNode>}
      @children = []

      @_richly_editable = false
      @_editable = false
      @focusable = false
      @_expanded = false
      @_name = payload.dig("name", "value") || ""
      @_role = payload.dig("role", "value") || "Unknown"

      payload.fetch("properties", []).each do |property|
        if property["name"] == "editable"
          @_richly_editable = property.dig("value", "value") == 'richtext'
          @_editable = true
        end
        if property["name"] == "focusable"
          @focusable = property.dig "value", "value"
        end
        if property["name"] == "expanded"
          @_expanded = property.dig "value", "value"
        end
      end
    end

    def find(&predicate)
      return self if predicate.(self)

      children.each do |child|
        result = child.find(&predicate)
        return result unless result.nil?
      end

      nil
    end

    def is_leaf_node
      return true if children.length.zero?

      # These types of objects may have children that we use as internal
      # implementation details, but we want to expose them as leaves to platform
      # accessibility APIs because screen readers might be confused if they find
      # any children.
      return true if plain_text_field? || text_only_object?

      # Roles whose children are only presentational according to the ARIA and
      # HTML5 Specs should be hidden from screen readers.
      # (Note that whilst ARIA buttons can have only presentational children, HTML5
      # buttons are allowed to have content.)
      return true if ['doc-cover', 'graphics-symbol', 'img', 'Meter', 'scrollbar', 'slider', 'separator', 'progressbar'].include? @_role

      # Here and below: Android heuristics
      return false if has_focusable_child?
      return true if focusable && @_name != ""
      return true if @_role == 'heading' && @_name
      false
    end

    def is_control
      control_roles =  [
        'button', 'checkbox', 'ColorWell', 'combobox', 'DisclosureTriangle',
        'listbox', 'menu', 'menubar', 'menuitem', 'menuitemcheckbox',
        'menuitemradio', 'radio', 'scrollbar', 'searchbox', 'slider',
        'spinbutton', 'switch', 'tab', 'textbox', 'tree'
      ]

      control_roles.include? @_role
    end

    def is_interesting(inside_control)
      return false if @_role == 'Ignored'

      return true if focusable || @_richly_editable

      # If it's not focusable but has a control role, then it's interesting.
      return true if is_control

      # A non focusable child of a control is not interesting
      return false if inside_control

      is_leaf_node && !!@_name
    end

    def serialize
      properties = payload.fetch("properties", []).each_with_object({}) do |property, memo|
        memo[property["name"].downcase] = property.dig "value", "value"
      end

      properties["name"] = payload.dig("name", "value") if payload["name"]
      properties["value"] = payload.dig("value", "value") if payload["value"]
      properties["description"] = payload.dig("description", "value") if payload["description"]

      node = { role: @_role }

      USER_STRING_PROPERTIES.each do |user_string_property|
        next unless properties.include? user_string_property

        node[user_string_property.to_sym] = properties[user_string_property]
      end

      BOOLEAN_PROPERTIEs.each do |boolean_property|
        #  WebArea's treat focus differently than other nodes. They report whether their frame  has focus,
        #  not whether focus is specifically on the root node.
        next if boolean_property == "focused" && @_role == "WebArea"

        next unless value = properties[boolean_property]

        node[boolean_property.to_sym] = value
      end

      TRISTATE_PROPERTIES.each do |tristate_property|
        next unless properties.include? tristate_property

        value = properties[tristate_property]

        node[tristate_property.to_sym] =
          case value
          when 'mixed' then mixed
          when 'true' then true
          else false
          end
      end

      NUMERICAL_PROPERTIES.each do |numerical_property|
        next unless properties.include? numerical_property

        node[numerical_property.to_sym] = properties[numerical_property]
      end

      TOKEN_PROPERTIES.each do |token_property|
        value = properties[token_property]

        next if value.nil? || value == "false"
        node[token_property.to_sym] = value
      end

      node
    end

    def has_focusable_child?
      @_has_focusable_child ||= children.any? { |child| child.focusable || child.has_focusable_child? }
    end

    private

      USER_STRING_PROPERTIES = [
        'name',
        'value',
        'description',
        'keyshortcuts',
        'roledescription',
        'valuetext',
      ]

      BOOLEAN_PROPERTIEs = [
        'disabled',
        'expanded',
        'focused',
        'modal',
        'multiline',
        'multiselectable',
        'readonly',
        'required',
        'selected',
      ]

      TRISTATE_PROPERTIES = ['checked', 'pressed']

      NUMERICAL_PROPERTIES = ['level', 'valuemax', 'valuemin']

      TOKEN_PROPERTIES = ['autocomplete', 'haspopup', 'invalid', 'orientation']

      def plain_text_field?
        return false if @_richly_editable
        return true if @_editable
        ['textbox', 'ComboBox', 'searchbox'].include? @_role
      end

      def text_only_object?
        ['LineBreak', 'text', 'InlineTextBox'].include? @_role
      end
  end
end
