# frozen_string_literal: true

# require "parser/source/map"

module Ratchet
  module Parsers
    class ParseResult
      attr_reader :location
      attr_reader :file
      attr_reader :message

      def initialize(file:, message:, location: nil)
        @location = location
        @file = file
        @message = message
      end

      def to_s(style = OutputStyles::Plain.new)
        location = self.location
        if location
          <<~EOS
            #{style.filename}#{file}#{style.reset}:#{location.line}:#{location.column}
            #{@message}
          EOS
        else
          <<~EOS
            #{style.filename}#{file}#{style.reset}
            #{@message}
          EOS
        end
      end
    end
  end
end
