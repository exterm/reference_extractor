# frozen_string_literal: true

module ReferenceExtractor
  module ParserTestHelper
    class << self
      def parse(source)
        Internal::Parsers::Ruby.new.call(io: StringIO.new(source))
      end
    end
  end
end
