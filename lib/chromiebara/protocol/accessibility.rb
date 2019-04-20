module Chromiebara
  module Protocol
    module Accessibility
      extend self

      # Disables the accessibility domain.
      # 
      #
      def disable
        {
          method: "Accessibility.disable"
        }
      end

      # Enables the accessibility domain which causes `AXNodeId`s to remain consistent between method calls.
      # This turns on accessibility for the page, which can impact performance until accessibility is disabled.
      # 
      #
      def enable
        {
          method: "Accessibility.enable"
        }
      end

      # Fetches the accessibility node and partial accessibility tree for this DOM node, if it exists.
      # 
      # @param node_id [Dom.nodeid] Identifier of the node to get the partial accessibility tree for.
      # @param backend_node_id [Dom.backendnodeid] Identifier of the backend node to get the partial accessibility tree for.
      # @param object_id [Runtime.remoteobjectid] JavaScript object id of the node wrapper to get the partial accessibility tree for.
      # @param fetch_relatives [Boolean] Whether to fetch this nodes ancestors, siblings and children. Defaults to true.
      #
      def get_partial_ax_tree(node_id: nil, backend_node_id: nil, object_id: nil, fetch_relatives: nil)
        {
          method: "Accessibility.getPartialAXTree",
          params: { nodeId: node_id, backendNodeId: backend_node_id, objectId: object_id, fetchRelatives: fetch_relatives }.compact
        }
      end

      # Fetches the entire accessibility tree
      # 
      #
      def get_full_ax_tree
        {
          method: "Accessibility.getFullAXTree"
        }
      end
    end
  end
end
