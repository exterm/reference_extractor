# frozen_string_literal: true

require "prism"

module ReferenceExtractor
  module Internal
    module Parsers
      class Ruby
        # Error types that should be ignored (valid in certain contexts like ERB)
        IGNORABLE_ERROR_TYPES = [:invalid_yield].to_set.freeze

        def call(io:, file_path: "<unknown>")
          source = io.read
          result = Prism.parse(source, filepath: file_path)

          if result.failure?
            # Filter out ignorable errors (e.g., yield outside block in ERB templates)
            fatal_errors = result.errors.reject { |e| IGNORABLE_ERROR_TYPES.include?(e.type) }
            if fatal_errors.any?
              message = fatal_errors.first&.message || "Parse error"
              raise ParseError, ParseResult.new(file: file_path, message: message)
            end
          end

          result.value # Prism::ProgramNode
        end
      end
    end
  end
end
