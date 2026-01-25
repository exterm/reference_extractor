# frozen_string_literal: true

require "prism"

module ReferenceExtractor
  module Internal
    # Convenience methods for working with Prism nodes.
    module NodeHelpers
      class TypeError < ArgumentError; end

      class << self
        def class_or_module_name(class_or_module_node)
          case class_or_module_node
          when Prism::ClassNode, Prism::ModuleNode
            constant_name(class_or_module_node.constant_path)
          else
            raise TypeError
          end
        end

        def constant_name(constant_node)
          case constant_node
          when Prism::ConstantReadNode
            constant_node.name.to_s
          when Prism::ConstantPathNode
            parent = constant_node.parent
            name = constant_node.name.to_s

            if parent.nil?
              # ::Foo - absolute path with no parent means root namespace
              "::#{name}"
            else
              parent_name = constant_name(parent)
              "#{parent_name}::#{name}"
            end
          when Prism::ConstantWriteNode
            constant_node.name.to_s
          when Prism::ConstantPathWriteNode
            constant_name(constant_node.target)
          when Prism::ConstantPathTargetNode
            parent = constant_node.parent
            name = constant_node.name.to_s

            if parent.nil?
              "::#{name}"
            else
              "#{constant_name(parent)}::#{name}"
            end
          when Prism::SelfNode
            raise TypeError
          else
            raise TypeError
          end
        end

        def enclosing_namespace_path(starting_node, ancestors:)
          ancestors.select { |n| n.is_a?(Prism::ClassNode) || n.is_a?(Prism::ModuleNode) }
            .each_with_object([]) do |node, namespace|
            # when evaluating `class Child < Parent`, the const node for `Parent` is a child of the class
            # node, so it'll be an ancestor, but `Parent` is not evaluated in the namespace of `Child`, so
            # we need to skip it here
            next if node.is_a?(Prism::ClassNode) && superclass_contains?(node, starting_node)

            namespace.prepend(class_or_module_name(node))
          end
        end

        def literal_value(string_or_symbol_node)
          case string_or_symbol_node
          when Prism::StringNode
            string_or_symbol_node.unescaped
          when Prism::SymbolNode
            string_or_symbol_node.value.to_sym
          else
            raise TypeError
          end
        end

        def location(node)
          loc = node.location
          Node::Location.new(loc.start_line, loc.start_column)
        end

        def constant?(node)
          node.is_a?(Prism::ConstantReadNode) || node.is_a?(Prism::ConstantPathNode)
        end

        def constant_assignment?(node)
          node.is_a?(Prism::ConstantWriteNode) || node.is_a?(Prism::ConstantPathWriteNode)
        end

        def class?(node)
          node.is_a?(Prism::ClassNode)
        end

        def module?(node)
          node.is_a?(Prism::ModuleNode)
        end

        def method_call?(node)
          node.is_a?(Prism::CallNode)
        end

        def hash?(node)
          node.is_a?(Prism::HashNode) || node.is_a?(Prism::KeywordHashNode)
        end

        def string?(node)
          node.is_a?(Prism::StringNode)
        end

        def symbol?(node)
          node.is_a?(Prism::SymbolNode)
        end

        def block?(node)
          node.is_a?(Prism::BlockNode)
        end

        def method_arguments(method_call_node)
          raise TypeError unless method_call?(method_call_node)

          method_call_node.arguments&.arguments || []
        end

        def method_name(method_call_node)
          raise TypeError unless method_call?(method_call_node)

          method_call_node.name
        end

        def module_name_from_definition(node)
          case node
          when Prism::ClassNode, Prism::ModuleNode
            class_or_module_name(node)
          when Prism::ConstantWriteNode, Prism::ConstantPathWriteNode
            rvalue = node.value

            case rvalue
            when Prism::CallNode
              # "Class.new" or "Module.new" or "Class.new do end"
              # In Prism, the block is a property of CallNode, not a separate node type
              constant_name(node) if module_creation?(rvalue)
            end
          end
        end

        def name_location(node)
          name_loc = case node
          when Prism::ConstantReadNode
            node.location
          when Prism::ConstantPathNode
            node.name_loc
          when Prism::ConstantWriteNode
            node.name_loc
          when Prism::ConstantPathWriteNode
            node.target.name_loc
          end

          Node::Location.new(name_loc.start_line, name_loc.start_column) if name_loc
        end

        def parent_class(class_node)
          raise TypeError unless class?(class_node)

          class_node.superclass
        end

        def parent_module_name(ancestors:)
          # In Prism, CallNode contains BlockNode (opposite of Parser gem)
          # So we look for CallNodes with blocks instead of BlockNodes
          definitions = ancestors
            .select { |n| class?(n) || module?(n) || constant_assignment?(n) || (method_call?(n) && n.block) }

          names = definitions.map do |definition|
            name_part_from_definition(definition)
          end.compact

          names.empty? ? "Object" : names.reverse.join("::")
        end

        def value_from_hash(hash_node, key)
          raise TypeError unless hash?(hash_node)

          pair = hash_node.elements.detect do |element|
            element.is_a?(Prism::AssocNode) &&
              (element.key.is_a?(Prism::SymbolNode) || element.key.is_a?(Prism::StringNode)) &&
              literal_value(element.key) == key
          end
          pair&.value
        end

        private

        def superclass_contains?(class_node, target_node)
          superclass = class_node.superclass
          return false unless superclass

          # Check if target_node is the superclass or contained within the superclass subtree
          return true if superclass == target_node

          node_contains?(superclass, target_node)
        end

        def node_contains?(node, target)
          return true if node == target

          node.child_nodes.compact.any? { |child| node_contains?(child, target) }
        end

        def module_creation?(node)
          # "Class.new" or "Module.new"
          method_call?(node) &&
            dynamic_class_creation?(node.receiver) &&
            method_name(node) == :new
        end

        def dynamic_class_creation?(node)
          !!node &&
            constant?(node) &&
            ["Class", "Module"].include?(constant_name(node))
        end

        def name_from_block_call(call_node)
          if call_node.name == :class_eval
            receiver = call_node.receiver
            constant_name(receiver) if receiver && constant?(receiver)
          end
        end

        def name_part_from_definition(node)
          case node
          when Prism::ClassNode, Prism::ModuleNode, Prism::ConstantWriteNode, Prism::ConstantPathWriteNode
            module_name_from_definition(node)
          when Prism::BlockNode
            # For blocks, look at the parent CallNode
            # Note: In Prism, BlockNode is a child of CallNode, not the other way around
            # The ancestors list should have the CallNode that owns this block
            nil
          when Prism::CallNode
            # This is a call node with a block (like class_eval)
            # Check if it's a class_eval call
            name_from_block_call(node)
          end
        end
      end
    end
  end
end
