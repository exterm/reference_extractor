# frozen_string_literal: true

module ReferenceExtractor
  module Internal
    # Extracts a constant name from an AST node of type :const
    class ConstNodeInspector
      def constant_name_from_node(node, ancestors:, relative_path: nil)
        return nil unless NodeHelpers.constant?(node)

        parent = ancestors.first

        # Only process the root `const` node for namespaced constant references. For example, in the
        # reference `Spam::Eggs::Thing`, we only process the const node associated with `Spam`.
        return nil unless root_constant?(parent)

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

      def root_constant?(parent)
        !(parent && NodeHelpers.constant?(parent))
      end

      def constant_in_module_or_class_definition?(node, parent:)
        parent_name = NodeHelpers.module_name_from_definition(parent)
        parent_name && parent_name == NodeHelpers.constant_name(node)
      end

      def fully_qualify_constant(ancestors)
        # We're defining a class with this name, in which case the constant is implicitly fully qualified by its
        # enclosing namespace
        "::" + NodeHelpers.parent_module_name(ancestors: ancestors)
      end
    end
  end
end
