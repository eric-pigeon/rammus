module Chromiebara
  module Protocol
    module DOM
      extend self

      # Collects class names for the node with given id and all of it's child nodes.
      # 
      # @param node_id [Nodeid] Id of the node to collect class names.
      #
      def collect_class_names_from_subtree(node_id:)
        {
          method: "DOM.collectClassNamesFromSubtree",
          params: { nodeId: node_id }.compact
        }
      end

      # Creates a deep copy of the specified node and places it into the target container before the
      # given anchor.
      # 
      # @param node_id [Nodeid] Id of the node to copy.
      # @param target_node_id [Nodeid] Id of the element to drop the copy into.
      # @param insert_before_node_id [Nodeid] Drop the copy before this node (if absent, the copy becomes the last child of `targetNodeId`).
      #
      def copy_to(node_id:, target_node_id:, insert_before_node_id: nil)
        {
          method: "DOM.copyTo",
          params: { nodeId: node_id, targetNodeId: target_node_id, insertBeforeNodeId: insert_before_node_id }.compact
        }
      end

      # Describes node given its id, does not require domain to be enabled. Does not start tracking any
      # objects, can be used for automation.
      # 
      # @param node_id [Nodeid] Identifier of the node.
      # @param backend_node_id [Backendnodeid] Identifier of the backend node.
      # @param object_id [Runtime.remoteobjectid] JavaScript object id of the node wrapper.
      # @param depth [Integer] The maximum depth at which children should be retrieved, defaults to 1. Use -1 for the entire subtree or provide an integer larger than 0.
      # @param pierce [Boolean] Whether or not iframes and shadow roots should be traversed when returning the subtree (default is false).
      #
      def describe_node(node_id: nil, backend_node_id: nil, object_id: nil, depth: nil, pierce: nil)
        {
          method: "DOM.describeNode",
          params: { nodeId: node_id, backendNodeId: backend_node_id, objectId: object_id, depth: depth, pierce: pierce }.compact
        }
      end

      # Disables DOM agent for the given page.
      # 
      #
      def disable
        {
          method: "DOM.disable"
        }
      end

      # Discards search results from the session with the given id. `getSearchResults` should no longer
      # be called for that search.
      # 
      # @param search_id [String] Unique search session identifier.
      #
      def discard_search_results(search_id:)
        {
          method: "DOM.discardSearchResults",
          params: { searchId: search_id }.compact
        }
      end

      # Enables DOM agent for the given page.
      # 
      #
      def enable
        {
          method: "DOM.enable"
        }
      end

      # Focuses the given element.
      # 
      # @param node_id [Nodeid] Identifier of the node.
      # @param backend_node_id [Backendnodeid] Identifier of the backend node.
      # @param object_id [Runtime.remoteobjectid] JavaScript object id of the node wrapper.
      #
      def focus(node_id: nil, backend_node_id: nil, object_id: nil)
        {
          method: "DOM.focus",
          params: { nodeId: node_id, backendNodeId: backend_node_id, objectId: object_id }.compact
        }
      end

      # Returns attributes for the specified node.
      # 
      # @param node_id [Nodeid] Id of the node to retrieve attibutes for.
      #
      def get_attributes(node_id:)
        {
          method: "DOM.getAttributes",
          params: { nodeId: node_id }.compact
        }
      end

      # Returns boxes for the given node.
      # 
      # @param node_id [Nodeid] Identifier of the node.
      # @param backend_node_id [Backendnodeid] Identifier of the backend node.
      # @param object_id [Runtime.remoteobjectid] JavaScript object id of the node wrapper.
      #
      def get_box_model(node_id: nil, backend_node_id: nil, object_id: nil)
        {
          method: "DOM.getBoxModel",
          params: { nodeId: node_id, backendNodeId: backend_node_id, objectId: object_id }.compact
        }
      end

      # Returns quads that describe node position on the page. This method
      # might return multiple quads for inline nodes.
      # 
      # @param node_id [Nodeid] Identifier of the node.
      # @param backend_node_id [Backendnodeid] Identifier of the backend node.
      # @param object_id [Runtime.remoteobjectid] JavaScript object id of the node wrapper.
      #
      def get_content_quads(node_id: nil, backend_node_id: nil, object_id: nil)
        {
          method: "DOM.getContentQuads",
          params: { nodeId: node_id, backendNodeId: backend_node_id, objectId: object_id }.compact
        }
      end

      # Returns the root DOM node (and optionally the subtree) to the caller.
      # 
      # @param depth [Integer] The maximum depth at which children should be retrieved, defaults to 1. Use -1 for the entire subtree or provide an integer larger than 0.
      # @param pierce [Boolean] Whether or not iframes and shadow roots should be traversed when returning the subtree (default is false).
      #
      def get_document(depth: nil, pierce: nil)
        {
          method: "DOM.getDocument",
          params: { depth: depth, pierce: pierce }.compact
        }
      end

      # Returns the root DOM node (and optionally the subtree) to the caller.
      # 
      # @param depth [Integer] The maximum depth at which children should be retrieved, defaults to 1. Use -1 for the entire subtree or provide an integer larger than 0.
      # @param pierce [Boolean] Whether or not iframes and shadow roots should be traversed when returning the subtree (default is false).
      #
      def get_flattened_document(depth: nil, pierce: nil)
        {
          method: "DOM.getFlattenedDocument",
          params: { depth: depth, pierce: pierce }.compact
        }
      end

      # Returns node id at given location. Depending on whether DOM domain is enabled, nodeId is
      # either returned or not.
      # 
      # @param x [Integer] X coordinate.
      # @param y [Integer] Y coordinate.
      # @param include_user_agent_shadow_dom [Boolean] False to skip to the nearest non-UA shadow root ancestor (default: false).
      #
      def get_node_for_location(x:, y:, include_user_agent_shadow_dom: nil)
        {
          method: "DOM.getNodeForLocation",
          params: { x: x, y: y, includeUserAgentShadowDOM: include_user_agent_shadow_dom }.compact
        }
      end

      # Returns node's HTML markup.
      # 
      # @param node_id [Nodeid] Identifier of the node.
      # @param backend_node_id [Backendnodeid] Identifier of the backend node.
      # @param object_id [Runtime.remoteobjectid] JavaScript object id of the node wrapper.
      #
      def get_outer_html(node_id: nil, backend_node_id: nil, object_id: nil)
        {
          method: "DOM.getOuterHTML",
          params: { nodeId: node_id, backendNodeId: backend_node_id, objectId: object_id }.compact
        }
      end

      # Returns the id of the nearest ancestor that is a relayout boundary.
      # 
      # @param node_id [Nodeid] Id of the node.
      #
      def get_relayout_boundary(node_id:)
        {
          method: "DOM.getRelayoutBoundary",
          params: { nodeId: node_id }.compact
        }
      end

      # Returns search results from given `fromIndex` to given `toIndex` from the search with the given
      # identifier.
      # 
      # @param search_id [String] Unique search session identifier.
      # @param from_index [Integer] Start index of the search result to be returned.
      # @param to_index [Integer] End index of the search result to be returned.
      #
      def get_search_results(search_id:, from_index:, to_index:)
        {
          method: "DOM.getSearchResults",
          params: { searchId: search_id, fromIndex: from_index, toIndex: to_index }.compact
        }
      end

      # Hides any highlight.
      # 
      #
      def hide_highlight
        {
          method: "DOM.hideHighlight"
        }
      end

      # Highlights DOM node.
      # 
      #
      def highlight_node
        {
          method: "DOM.highlightNode"
        }
      end

      # Highlights given rectangle.
      # 
      #
      def highlight_rect
        {
          method: "DOM.highlightRect"
        }
      end

      # Marks last undoable state.
      # 
      #
      def mark_undoable_state
        {
          method: "DOM.markUndoableState"
        }
      end

      # Moves node into the new container, places it before the given anchor.
      # 
      # @param node_id [Nodeid] Id of the node to move.
      # @param target_node_id [Nodeid] Id of the element to drop the moved node into.
      # @param insert_before_node_id [Nodeid] Drop node before this one (if absent, the moved node becomes the last child of `targetNodeId`).
      #
      def move_to(node_id:, target_node_id:, insert_before_node_id: nil)
        {
          method: "DOM.moveTo",
          params: { nodeId: node_id, targetNodeId: target_node_id, insertBeforeNodeId: insert_before_node_id }.compact
        }
      end

      # Searches for a given string in the DOM tree. Use `getSearchResults` to access search results or
      # `cancelSearch` to end this search session.
      # 
      # @param query [String] Plain text or query selector or XPath search query.
      # @param include_user_agent_shadow_dom [Boolean] True to search in user agent shadow DOM.
      #
      def perform_search(query:, include_user_agent_shadow_dom: nil)
        {
          method: "DOM.performSearch",
          params: { query: query, includeUserAgentShadowDOM: include_user_agent_shadow_dom }.compact
        }
      end

      # Requests that the node is sent to the caller given its path. // FIXME, use XPath
      # 
      # @param path [String] Path to node in the proprietary format.
      #
      def push_node_by_path_to_frontend(path:)
        {
          method: "DOM.pushNodeByPathToFrontend",
          params: { path: path }.compact
        }
      end

      # Requests that a batch of nodes is sent to the caller given their backend node ids.
      # 
      # @param backend_node_ids [Array] The array of backend node ids.
      #
      def push_nodes_by_backend_ids_to_frontend(backend_node_ids:)
        {
          method: "DOM.pushNodesByBackendIdsToFrontend",
          params: { backendNodeIds: backend_node_ids }.compact
        }
      end

      # Executes `querySelector` on a given node.
      # 
      # @param node_id [Nodeid] Id of the node to query upon.
      # @param selector [String] Selector string.
      #
      def query_selector(node_id:, selector:)
        {
          method: "DOM.querySelector",
          params: { nodeId: node_id, selector: selector }.compact
        }
      end

      # Executes `querySelectorAll` on a given node.
      # 
      # @param node_id [Nodeid] Id of the node to query upon.
      # @param selector [String] Selector string.
      #
      def query_selector_all(node_id:, selector:)
        {
          method: "DOM.querySelectorAll",
          params: { nodeId: node_id, selector: selector }.compact
        }
      end

      # Re-does the last undone action.
      # 
      #
      def redo
        {
          method: "DOM.redo"
        }
      end

      # Removes attribute with given name from an element with given id.
      # 
      # @param node_id [Nodeid] Id of the element to remove attribute from.
      # @param name [String] Name of the attribute to remove.
      #
      def remove_attribute(node_id:, name:)
        {
          method: "DOM.removeAttribute",
          params: { nodeId: node_id, name: name }.compact
        }
      end

      # Removes node with given id.
      # 
      # @param node_id [Nodeid] Id of the node to remove.
      #
      def remove_node(node_id:)
        {
          method: "DOM.removeNode",
          params: { nodeId: node_id }.compact
        }
      end

      # Requests that children of the node with given id are returned to the caller in form of
      # `setChildNodes` events where not only immediate children are retrieved, but all children down to
      # the specified depth.
      # 
      # @param node_id [Nodeid] Id of the node to get children for.
      # @param depth [Integer] The maximum depth at which children should be retrieved, defaults to 1. Use -1 for the entire subtree or provide an integer larger than 0.
      # @param pierce [Boolean] Whether or not iframes and shadow roots should be traversed when returning the sub-tree (default is false).
      #
      def request_child_nodes(node_id:, depth: nil, pierce: nil)
        {
          method: "DOM.requestChildNodes",
          params: { nodeId: node_id, depth: depth, pierce: pierce }.compact
        }
      end

      # Requests that the node is sent to the caller given the JavaScript node object reference. All
      # nodes that form the path from the node to the root are also sent to the client as a series of
      # `setChildNodes` notifications.
      # 
      # @param object_id [Runtime.remoteobjectid] JavaScript object id to convert into node.
      #
      def request_node(object_id:)
        {
          method: "DOM.requestNode",
          params: { objectId: object_id }.compact
        }
      end

      # Resolves the JavaScript node object for a given NodeId or BackendNodeId.
      # 
      # @param node_id [Nodeid] Id of the node to resolve.
      # @param backend_node_id [Dom.backendnodeid] Backend identifier of the node to resolve.
      # @param object_group [String] Symbolic group name that can be used to release multiple objects.
      # @param execution_context_id [Runtime.executioncontextid] Execution context in which to resolve the node.
      #
      def resolve_node(node_id: nil, backend_node_id: nil, object_group: nil, execution_context_id: nil)
        {
          method: "DOM.resolveNode",
          params: { nodeId: node_id, backendNodeId: backend_node_id, objectGroup: object_group, executionContextId: execution_context_id }.compact
        }
      end

      # Sets attribute for an element with given id.
      # 
      # @param node_id [Nodeid] Id of the element to set attribute for.
      # @param name [String] Attribute name.
      # @param value [String] Attribute value.
      #
      def set_attribute_value(node_id:, name:, value:)
        {
          method: "DOM.setAttributeValue",
          params: { nodeId: node_id, name: name, value: value }.compact
        }
      end

      # Sets attributes on element with given id. This method is useful when user edits some existing
      # attribute value and types in several attribute name/value pairs.
      # 
      # @param node_id [Nodeid] Id of the element to set attributes for.
      # @param text [String] Text with a number of attributes. Will parse this text using HTML parser.
      # @param name [String] Attribute name to replace with new attributes derived from text in case text parsed successfully.
      #
      def set_attributes_as_text(node_id:, text:, name: nil)
        {
          method: "DOM.setAttributesAsText",
          params: { nodeId: node_id, text: text, name: name }.compact
        }
      end

      # Sets files for the given file input element.
      # 
      # @param files [Array] Array of file paths to set.
      # @param node_id [Nodeid] Identifier of the node.
      # @param backend_node_id [Backendnodeid] Identifier of the backend node.
      # @param object_id [Runtime.remoteobjectid] JavaScript object id of the node wrapper.
      #
      def set_file_input_files(files:, node_id: nil, backend_node_id: nil, object_id: nil)
        {
          method: "DOM.setFileInputFiles",
          params: { files: files, nodeId: node_id, backendNodeId: backend_node_id, objectId: object_id }.compact
        }
      end

      # Returns file information for the given
      # File wrapper.
      # 
      # @param object_id [Runtime.remoteobjectid] JavaScript object id of the node wrapper.
      #
      def get_file_info(object_id:)
        {
          method: "DOM.getFileInfo",
          params: { objectId: object_id }.compact
        }
      end

      # Enables console to refer to the node with given id via $x (see Command Line API for more details
      # $x functions).
      # 
      # @param node_id [Nodeid] DOM node id to be accessible by means of $x command line API.
      #
      def set_inspected_node(node_id:)
        {
          method: "DOM.setInspectedNode",
          params: { nodeId: node_id }.compact
        }
      end

      # Sets node name for a node with given id.
      # 
      # @param node_id [Nodeid] Id of the node to set name for.
      # @param name [String] New node's name.
      #
      def set_node_name(node_id:, name:)
        {
          method: "DOM.setNodeName",
          params: { nodeId: node_id, name: name }.compact
        }
      end

      # Sets node value for a node with given id.
      # 
      # @param node_id [Nodeid] Id of the node to set value for.
      # @param value [String] New node's value.
      #
      def set_node_value(node_id:, value:)
        {
          method: "DOM.setNodeValue",
          params: { nodeId: node_id, value: value }.compact
        }
      end

      # Sets node HTML markup, returns new node id.
      # 
      # @param node_id [Nodeid] Id of the node to set markup for.
      # @param outer_html [String] Outer HTML markup to set.
      #
      def set_outer_html(node_id:, outer_html:)
        {
          method: "DOM.setOuterHTML",
          params: { nodeId: node_id, outerHTML: outer_html }.compact
        }
      end

      # Undoes the last performed action.
      # 
      #
      def undo
        {
          method: "DOM.undo"
        }
      end

      # Returns iframe node that owns iframe with the given domain.
      # 
      #
      def get_frame_owner(frame_id:)
        {
          method: "DOM.getFrameOwner",
          params: { frameId: frame_id }.compact
        }
      end
    end
  end
end
