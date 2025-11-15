# frozen_string_literal: true

module ReferenceExtractor
  module Parsers
    extend ActiveSupport::Autoload

    autoload :Erb
    autoload :Factory
    autoload :Ruby
    autoload :ParseResult

    class ParseError < StandardError
      attr_reader(:result)

      def initialize(result)
        super(result.message)
        @result = result
      end
    end
  end
end
