# frozen_string_literal: true

require "stringio"
require "herb"

module ReferenceExtractor
  module Parsers
    class Erb
      def initialize(parser: Herb.method(:extract_ruby), ruby_parser: Ruby.new)
        @parser = parser
        @ruby_parser = ruby_parser
      end

      def call(io:, file_path: "<unknown>")
        erb_source = io.read
        ruby_code = @parser.call(erb_source)

        @ruby_parser.call(
          io: StringIO.new(ruby_code),
          file_path: file_path
        )
      end
    end
  end
end
