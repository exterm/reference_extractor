# frozen_string_literal: true

module Ratchet
  # Extracts a possible constant reference from a given AST node.
  class ReferenceExtractor
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
      root_node:,
      root_path:
    )
      @constant_name_inspectors = constant_name_inspectors
      @root_path = root_path
      @local_constant_definitions = ParsedConstantDefinitions.new(root_node: root_node)
    end

    def reference_from_node(node, ancestors:, relative_path:)
      constant_name = nil

      @constant_name_inspectors.each do |inspector|
        constant_name = inspector.constant_name_from_node(node, ancestors:)

        break if constant_name
      end

      if constant_name
        reference_from_constant(
          constant_name,
          node:,
          ancestors:,
          relative_path:
        )
      end
    end

    private

    def reference_from_constant(constant_name, node:, ancestors:, relative_path:)
      namespace_path = NodeHelpers.enclosing_namespace_path(node, ancestors: ancestors)

      return if local_reference?(constant_name, NodeHelpers.name_location(node), namespace_path)

      UnresolvedReference.new(
        constant_name:,
        namespace_path:,
        relative_path: relative_path,
        source_location: NodeHelpers.location(node)
      )
    end

    def local_reference?(constant_name, name_location, namespace_path)
      @local_constant_definitions.local_reference?(
        constant_name,
        location: name_location,
        namespace_path: namespace_path
      )
    end
  end

  private_constant :ReferenceExtractor
end
