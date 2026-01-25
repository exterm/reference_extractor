# frozen_string_literal: true

module ReferenceExtractor
  module Internal
    # Extracts a possible constant reference from a given AST node.
    class AstReferenceExtractor
      class << self
        def get_fully_qualified_references_from(unresolved_references, context_provider)
          fully_qualified_references = []

          unresolved_references.each do |unresolved_reference|
            constant =
              context_provider.context_for(
                unresolved_reference.constant_name,
                current_namespace_path: unresolved_reference.namespace_path
              )

            next if constant.nil?

            # Ignore references that resolve to the same file they originate from.
            next if constant.location == unresolved_reference.relative_path

            fully_qualified_references << Reference.new(
              relative_path: unresolved_reference.relative_path,
              constant: constant,
              source_location: unresolved_reference.source_location
            )
          end

          fully_qualified_references
        end
      end

      def initialize(
        constant_name_inspectors:,
        context_provider:,
        root_path:
      )
        @constant_name_inspectors = constant_name_inspectors
        @context_provider = context_provider
        @root_path = root_path
      end

      # Extract and resolve all references from the AST in one step
      def extract_references(root_node, relative_path:)
        local_constant_definitions = ParsedConstantDefinitions.new(root_node: root_node)
        unresolved_references = []
        collect_references(
          root_node,
          ancestors: [],
          relative_path: relative_path,
          local_constant_definitions: local_constant_definitions,
          references: unresolved_references
        )
        self.class.get_fully_qualified_references_from(unresolved_references, @context_provider)
      end

      def reference_from_node(node, ancestors:, relative_path:, local_constant_definitions:)
        constant_name = nil

        @constant_name_inspectors.each do |inspector|
          constant_name = inspector.constant_name_from_node(node, ancestors:, relative_path:)

          break if constant_name
        end

        if constant_name
          reference_from_constant(
            constant_name,
            node:,
            ancestors:,
            relative_path:,
            local_constant_definitions:
          )
        end
      end

      private

      def reference_from_constant(constant_name, node:, ancestors:, relative_path:, local_constant_definitions:)
        namespace_path = NodeHelpers.enclosing_namespace_path(node, ancestors: ancestors)

        return if local_reference?(constant_name, NodeHelpers.name_location(node), namespace_path, local_constant_definitions)

        UnresolvedReference.new(
          constant_name:,
          namespace_path:,
          relative_path: relative_path,
          source_location: NodeHelpers.location(node)
        )
      end

      def local_reference?(constant_name, name_location, namespace_path, local_constant_definitions)
        local_constant_definitions.local_reference?(
          constant_name,
          location: name_location,
          namespace_path: namespace_path
        )
      end

      def collect_references(node, ancestors:, relative_path:, local_constant_definitions:, references:)
        reference = reference_from_node(
          node,
          ancestors:,
          relative_path:,
          local_constant_definitions:
        )
        references << reference if reference

        ancestors.unshift(node)
        NodeHelpers.each_child(node) do |child|
          collect_references(
            child,
            ancestors:,
            relative_path:,
            local_constant_definitions:,
            references:
          )
        end
        ancestors.shift

        references
      end
    end
  end
end
