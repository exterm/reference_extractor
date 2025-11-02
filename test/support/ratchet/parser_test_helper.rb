# frozen_string_literal: true

module Ratchet
  module ParserTestHelper
    class << self
      def parse(source)
        Parsers::Ruby.new.call(io: StringIO.new(source))
      end
    end
  end
end
