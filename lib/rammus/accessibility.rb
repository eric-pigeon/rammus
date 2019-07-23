require 'rammus/ax_node'

module Rammus
  class Accessibility
    include Promise::Await

    attr_reader :client

    # @param [Rammus::CDPSession] client
    #
    def initialize(client)
      @client = client
    end

    # @param {{interestingOnly?: boolean, root?: ?Puppeteer.ElementHandle}=} options
    # @return {!Promise<!SerializedAXNode>}
    #
    def snapshot(root: nil, interesting_only: true)
      nodes = (await client.command Protocol::Accessibility.get_full_ax_tree)["nodes"]
      backend_node_id = nil
      if root
        node = await client.command Protocol::DOM.describe_node object_id: root.remote_object["objectId"]
        backend_node_id = node.dig "node", "backendNodeId"
      end
      default_root = AXNode.create_tree nodes
      needle = default_root

      if backend_node_id
        needle = default_root.find do |n|
          n.payload["backendDOMNodeId"] == backend_node_id
        end
        return if needle.nil?
      end

      return Accessibility.serialize_tree(needle)[0] unless interesting_only

      interesting_nodes = Set.new
      Accessibility.collect_interesting_nodes interesting_nodes, default_root, false
      return unless interesting_nodes.include? needle

      Accessibility.serialize_tree(needle, interesting_nodes)[0]
    end

    private

      # @param {!AXNode} node
      # @param {!Set<!AXNode>=} whitelistedNodes
      # @return {!Array<!SerializedAXNode>}
      #
      def self.serialize_tree(node, whitelisted_nodes = nil)
        # @type {!Array<!SerializedAXNode>}
        children = node.children.flat_map do |child|
          Accessibility.serialize_tree child, whitelisted_nodes
        end

        if whitelisted_nodes && !whitelisted_nodes.include?(node)
          return children
        end

        serialized_node = node.serialize
        serialized_node[:children] = children unless children.length.zero?
        [serialized_node]
      end

      def self.collect_interesting_nodes(collection, node, inside_control)
        collection << node if node.is_interesting inside_control

        return if node.is_leaf_node

        inside_control ||= node.is_control

        node.children.each { |child| Accessibility.collect_interesting_nodes collection, child, inside_control }
      end
  end
end
