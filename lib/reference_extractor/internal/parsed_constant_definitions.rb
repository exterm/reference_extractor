# frozen_string_literal: true

require "prism"

module ReferenceExtractor
  module Internal
    # A collection of constant definitions parsed from an Abstract Syntax Tree (AST).
    class ParsedConstantDefinitions
      class << self
        # What fully qualified constants can this constant refer to in this context?
        def reference_qualifications(constant_name, namespace_path:)
          return [constant_name] if constant_name.start_with?("::")

          resolved_constant_name = "::#{constant_name}"

          possible_namespaces = namespace_path.each_with_object([""]) do |current, acc|
            acc << "#{acc.last}::#{current}" if current
          end

          possible_namespaces.map { |namespace| namespace + resolved_constant_name }
        end
      end

      def initialize(root_node:)
        @local_definitions = {}

        if root_node
          visitor = DefinitionCollectorVisitor.new
          root_node.accept(visitor)
          @local_definitions = visitor.definitions
        end
      end

      def local_reference?(constant_name, location: nil, namespace_path: [])
        qualifications = self.class.reference_qualifications(constant_name, namespace_path: namespace_path)

        qualifications.any? do |name|
          @local_definitions[name] &&
            @local_definitions[name] != location
        end
      end

      # Visitor that collects constant definitions from the AST
      class DefinitionCollectorVisitor < Prism::Visitor
        attr_reader :definitions

        def initialize
          super
          @definitions = {}
          @namespace_path = []
        end

        # Simple constant assignment: HELLO = "World"
        def visit_constant_write_node(node)
          add_definition(node.name.to_s, NodeHelpers.name_location(node))
          super
        end

        # Namespaced constant assignment: My::HELLO = "World"
        def visit_constant_path_write_node(node)
          # Skip dynamic constant paths like self::CONSTANT
          begin
            name = NodeHelpers.constant_name(node)
            add_definition(name, NodeHelpers.name_location(node))
          rescue NodeHelpers::TypeError
            # Dynamic constant path (e.g., self::CONSTANT), skip it
          end
          super
        end

        def visit_class_node(node)
          visit_class_or_module(node)
        end

        def visit_module_node(node)
          visit_class_or_module(node)
        end

        private

        def visit_class_or_module(node)
          name = NodeHelpers.class_or_module_name(node)
          parts = name.split("::")

          # For compact notation like "module Sales::Order", add all intermediate constants
          # Sales, then Sales::Order
          parts.each_with_index do |_part, index|
            partial_name = parts[0..index].join("::")
            # For compact notation, the name_location points to the full path
            # We use the same location for all parts
            add_definition(partial_name, name_location_for_class_or_module(node))
          end

          # Push all parts onto namespace for children
          @namespace_path.concat(parts)
          begin
            # Visit the body (children)
            node.body&.accept(self)
          ensure
            parts.length.times { @namespace_path.pop }
          end
        end

        def name_location_for_class_or_module(node)
          # For class/module nodes, we want the location of the constant path
          constant_path = node.constant_path
          case constant_path
          when Prism::ConstantReadNode
            NodeHelpers.location(constant_path)
          when Prism::ConstantPathNode
            # Find the leftmost (first) constant in the path
            leftmost = constant_path
            while leftmost.is_a?(Prism::ConstantPathNode) && leftmost.parent.is_a?(Prism::ConstantPathNode)
              leftmost = leftmost.parent
            end
            if leftmost.is_a?(Prism::ConstantPathNode) && leftmost.parent.is_a?(Prism::ConstantReadNode)
              NodeHelpers.location(leftmost.parent)
            elsif leftmost.is_a?(Prism::ConstantPathNode)
              Node::Location.new(leftmost.name_loc.start_line, leftmost.name_loc.start_column)
            else
              NodeHelpers.location(leftmost)
            end
          end
        end

        def add_definition(constant_name, location)
          resolved_constant = [""].concat(@namespace_path).push(constant_name).join("::")
          @definitions[resolved_constant] = location
        end
      end
    end
  end
end
