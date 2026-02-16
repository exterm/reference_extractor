# frozen_string_literal: true

module ReferenceExtractor
  module Internal
    # Get information about unresolved constants without loading the application code.
    # Information gathered: Fully qualified name and path to file containing the definition.
    #
    # The implementation makes a few assumptions about the code base:
    # - `Something::SomeOtherThing` is defined in a path of either `something/some_other_thing.rb` or `something.rb`,
    #   relative to the load path. Rails' `zeitwerk` autoloader makes the same assumption.
    # - It is OK to not always infer the exact file defining the constant. For example, when a constant is inherited, we
    #   have no way of inferring the file it is defined in. You could argue though that inheritance means that another
    #   constant with the same name exists in the inheriting class, and this view is sufficient for all our use cases.
    class ConstantDiscovery
      class Error < StandardError; end

      def initialize(root_path:, loaders:)
        @root_path = root_path
        @loaders = loaders
      end

      # Analyze a constant via its name.
      # If the constant is unresolved, we need the current namespace path to correctly infer its full name
      #
      # @param const_name [String] The unresolved constant's name.
      # @param current_namespace_path [Array<String>] (optional) The namespace of the context in which the constant is
      #   used, e.g. ["Apps", "Models"] for `Apps::Models`. Defaults to [] which means top level.
      # @return [ConstantContext]
      def context_for(const_name, current_namespace_path: [])
        current_namespace_path = [] if const_name.start_with?("::")
        const_name, location = resolve_constant(const_name.delete_prefix("::"), current_namespace_path)

        return unless location

        relative_location = relative_location_for(location)
        ConstantContext.new(const_name, relative_location)
      end

      # Analyze the constants and raise errors if any potential issues are encountered that would prevent
      # resolving the context for constants, such as ambiguous constant locations.
      #
      # @return [ConstantDiscovery]
      def validate_constants
        const_locations
        true
      end

      private

      def relative_location_for(location)
        @relative_location_cache ||= {}
        @relative_location_cache[location] ||= Pathname.new(location).relative_path_from(@root_path)
      end

      def const_locations
        return @const_locations unless @const_locations.nil?

        all_cpaths = @loaders.inject({}) do |cpaths, loader|
          paths = loader.all_expected_cpaths.filter do |cpath, _const|
            cpath.ends_with?(".rb")
          end
          cpaths.merge(paths)
        end
        paths_by_const = all_cpaths.invert
        validate_constant_paths(paths_by_const, all_cpaths: all_cpaths)
        @const_locations = paths_by_const
      end

      def resolve_constant(const_name, current_namespace_path, original_name: const_name)
        namespace, location = resolve_traversing_namespace_path(const_name, current_namespace_path)
        if location
          ["::" + namespace.push(original_name).join("::"), location]
        elsif !const_name.include?("::")
          # constant could not be resolved to a file in the given load paths
          [nil, nil]
        else
          parent_constant = const_name.split("::")[0..-2].join("::")
          resolve_constant(parent_constant, current_namespace_path, original_name:)
        end
      end

      def resolve_traversing_namespace_path(const_name, current_namespace_path)
        fully_qualified_name_guess = (current_namespace_path + [const_name]).join("::")

        location = const_locations[fully_qualified_name_guess]
        if location || fully_qualified_name_guess == const_name
          [current_namespace_path, location]
        else
          resolve_traversing_namespace_path(const_name, current_namespace_path[0..-2])
        end
      end

      def validate_constant_paths(paths_by_constant, all_cpaths:)
        raise(Error, "Could not find any ruby files.") if all_cpaths.empty?

        is_ambiguous = all_cpaths.size != paths_by_constant.size
        raise(Error, ambiguous_constants_hint(all_cpaths: all_cpaths)) if is_ambiguous
      end

      def ambiguous_constants_hint(all_cpaths:)
        paths_by_constant = all_cpaths.each_with_object({}) do |(path, constant), grouped|
          grouped[constant] ||= []
          grouped[constant] << path
        end
        ambiguous_constants = paths_by_constant.select { |_constant, paths| paths.size > 1 }

        <<~MSG
          Ambiguous constant definition:
          #{ambiguous_constants.map do |constant, paths|
              " - #{constant}:\n#{paths.map { |path| "   - #{relative_location_for(path)}" }.join("\n")}"
            end.join("\n")}
        MSG
      end
    end
  end
end
