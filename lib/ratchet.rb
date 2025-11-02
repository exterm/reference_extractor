# frozen_string_literal: true

require "active_support"
# Provides String#pluralize, ends_with?, and others
require "active_support/core_ext/string"

module Ratchet
  extend ActiveSupport::Autoload

  # public API
  # ...

  # private API
  autoload :ConstantDiscovery
  autoload :ConstantContext
  autoload :ConstNodeInspector
  autoload :Node
  autoload :NodeHelpers
  autoload :ParsedConstantDefinitions
  autoload :Parsers
  autoload :Reference
  autoload :ReferenceExtractor
  autoload :UnresolvedReference
end

require "ratchet/version"
