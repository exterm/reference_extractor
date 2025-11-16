# frozen_string_literal: true

require "parser"
require "prism"

module ReferenceExtractor
  module Internal
    module Parsers
      class Ruby
        class RaiseExceptionsParser < Prism::Translation::Parser
          def initialize(builder)
            super
            super.diagnostics.all_errors_are_fatal = true
          end
        end

        class TolerateInvalidUtf8Builder < Prism::Translation::Parser::Builder
          def string_value(token)
            value(token)
          end
        end

        def initialize(parser_class: RaiseExceptionsParser)
          @builder = TolerateInvalidUtf8Builder.new
          @parser_class = parser_class
        end

        def call(io:, file_path: "<unknown>")
          buffer = Parser::Source::Buffer.new(file_path)
          buffer.source = io.read
          parser = @parser_class.new(@builder)
          parser.parse(buffer)
        rescue EncodingError => e
          result = ParseResult.new(file: file_path, message: e.message)
          raise ParseError, result
        rescue Parser::SyntaxError => e
          result = ParseResult.new(file: file_path, message: "Syntax error: #{e}")
          raise ParseError, result
        end
      end
    end
  end
end
