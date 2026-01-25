# frozen_string_literal: true

require "prism"

module ReferenceExtractor
  module Internal
    # Extracts a constant name from a Prism ConstantReadNode or ConstantPathNode
    class ConstNodeInspector
      def constant_name_from_node(node, ancestors:, relative_path: nil)
        return nil unless NodeHelpers.constant?(node)

        parent = ancestors.first

        # Only process the root constant node for namespaced constant references. For example, in the
        # reference `Spam::Eggs::Thing`, we only process the const node associated with `Thing` (the
        # ConstantPathNode), not the intermediate ConstantReadNodes.
        return nil unless root_constant?(node, parent)

        if parent && constant_in_module_or_class_definition?(node, parent: parent)
          fully_qualify_constant(ancestors)
        else
          begin
            NodeHelpers.constant_name(node)
          rescue NodeHelpers::TypeError
            nil
          end
        end
      end

      private

      def root_constant?(node, parent)
        # A constant is a "root" if its parent is not a ConstantPathNode that contains it
        # In Prism, ConstantPathNode has a `parent` property and a `name` property
        # So if our node is the `parent` of a ConstantPathNode ancestor, we're not the root

        # If parent is a ConstantPathNode and this node is its `parent` (namespace), skip it
        return false if parent.is_a?(Prism::ConstantPathNode) && parent.parent == node

        true
      end

      def constant_in_module_or_class_definition?(node, parent:)
        parent_name = NodeHelpers.module_name_from_definition(parent)
        return false unless parent_name

        begin
          parent_name == NodeHelpers.constant_name(node)
        rescue NodeHelpers::TypeError
          false
        end
      end

      def fully_qualify_constant(ancestors)
        # We're defining a class with this name, in which case the constant is implicitly fully qualified by its
        # enclosing namespace
        "::" + NodeHelpers.parent_module_name(ancestors: ancestors)
      end
    end
  end
end
