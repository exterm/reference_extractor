# frozen_string_literal: true

module ReferenceExtractor
  # Public API for extracting constant references from Ruby code (that is autoloaded via Zeitwerk).
  #
  # @example
  #   extractor = ReferenceExtractor::Extractor.new(autoloaders: Rails.autoloaders, root_path: Rails.root)
  #   references = extractor.references_from_string("Order.find(1)")
  #   references = extractor.references_from_file("app/models/user.rb")
  class Extractor
    attr_reader :root_path

    # @param autoloaders [Enumerable] Collection of Zeitwerk loaders, e.g. from `Rails.autoloaders`
    # @param root_path [String, Pathname] The root path of the application, e.g. from `Rails.root`
    def initialize(autoloaders:, root_path:)
      @autoloaders = autoloaders
      @root_path = Pathname.new(root_path)
      @context_provider = Internal::ConstantDiscovery.new(root_path:, loaders: @autoloaders)
    end

    # Extract constant references from a Ruby code string.
    #
    # @param snippet [String] The Ruby code to analyze
    # @return [Array<Reference>] Array of references to autoloaded constants in project files
    def references_from_string(snippet)
      ast = parse_ruby_string(snippet)
      return [] unless ast

      extract_references(ast, relative_path: Pathname.new("<snippet>"))
    end

    # Extract constant references from a Ruby file.
    #
    # @param file_path [String, Pathname] Path to the Ruby file (relative to root_path or absolute)
    # @return [Array<Reference>] Array of references to autoloaded constants in project files
    def references_from_file(file_path)
      absolute_path = Pathname.new(file_path).expand_path(root_path)
      return [] unless File.exist?(absolute_path)

      ast = parse_file(absolute_path)
      return [] unless ast

      relative_path = Pathname.new(absolute_path).relative_path_from(root_path)
      extract_references(ast, relative_path:)
    end

    private

    def parse_ruby_string(snippet)
      parser = Internal::Parsers::Ruby.new
      parser.call(io: StringIO.new(snippet))
    end

    def parse_file(file_path)
      parser = Internal::Parsers::Factory.instance.for_path(file_path.to_s)
      raise ArgumentError, "Unsupported file type: #{file_path}" unless parser

      File.open(file_path, "r") do |io|
        parser.call(io:, file_path: file_path.to_s)
      end
    end

    def extract_references(root_node, relative_path:)
      ast_reference_extractor.extract_references(root_node, relative_path:)
    end

    def ast_reference_extractor
      @ast_reference_extractor ||= Internal::AstReferenceExtractor.new(
        constant_name_inspectors: [
          Internal::ConstNodeInspector.new,
          Internal::AssociationInspector.new
        ],
        context_provider: @context_provider,
        root_path:
      )
    end
  end
end
