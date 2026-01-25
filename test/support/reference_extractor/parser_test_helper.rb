# frozen_string_literal: true

module ReferenceExtractor
  module ParserTestHelper
    class << self
      def parse(source)
        result = Internal::Parsers::Ruby.new.call(io: StringIO.new(source))
        # Extract the first statement from the ProgramNode for compatibility with old tests
        # that expected to get the actual node directly
        unwrap_program_node(result)
      end

      def parse_raw(source)
        # Return the full ProgramNode without unwrapping
        Internal::Parsers::Ruby.new.call(io: StringIO.new(source))
      end

      private

      def unwrap_program_node(node)
        return node unless node.is_a?(Prism::ProgramNode)

        statements = node.statements&.body
        return node if statements.nil? || statements.empty?

        # Return the first statement if there's only one
        statements.length == 1 ? statements.first : node
      end
    end
  end
end
