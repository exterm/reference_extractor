# frozen_string_literal: true

module ReferenceExtractor
  module Internal
    # Extracts the implicit constant reference from an Active Record association
    class AssociationInspector
      RAILS_ASSOCIATIONS = [
        :belongs_to,
        :has_many,
        :has_one,
        :has_and_belongs_to_many
      ].to_set

      DEFAULT_EXCLUDED_FILES = Set.new([
        "spec/factories/**",
        "test/factories/**"
      ])

      def initialize(
        inflector: ActiveSupport::Inflector,
        custom_associations: Set.new,
        excluded_files: DEFAULT_EXCLUDED_FILES
      )
        @inflector = inflector
        @associations = RAILS_ASSOCIATIONS + custom_associations
        @excluded_files = excluded_files
      end

      def constant_name_from_node(node, ancestors:, relative_path:)
        return unless NodeHelpers.method_call?(node)
        return if excluded?(relative_path)
        return unless association?(node)

        arguments = NodeHelpers.method_arguments(node)
        association_name = association_name(arguments)
        return unless association_name

        if (class_name_node = custom_class_name(arguments))
          return unless NodeHelpers.string?(class_name_node)

          NodeHelpers.literal_value(class_name_node)
        else
          @inflector.classify(association_name.to_s)
        end
      end

      private

      def excluded?(relative_file)
        @excluded_files.any? do |pattern|
          relative_file.fnmatch?(pattern, File::FNM_PATHNAME | File::FNM_EXTGLOB)
        end
      end

      def association?(node)
        method_name = NodeHelpers.method_name(node)
        @associations.include?(method_name)
      end

      def custom_class_name(arguments)
        association_options = arguments.detect { |n| NodeHelpers.hash?(n) }
        return unless association_options

        NodeHelpers.value_from_hash(association_options, :class_name)
      end

      def association_name(arguments)
        association_name_node = arguments[0]
        return unless association_name_node
        return unless NodeHelpers.symbol?(association_name_node)

        NodeHelpers.literal_value(association_name_node)
      end
    end
  end
end
