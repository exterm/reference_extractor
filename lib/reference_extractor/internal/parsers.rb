# frozen_string_literal: true

module ReferenceExtractor
  module Internal
    module Parsers
      extend ActiveSupport::Autoload

      autoload :Erb
      autoload :Factory
      autoload :Ruby
      autoload :ParseResult
    end
  end
end
