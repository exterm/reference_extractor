# frozen_string_literal: true

module ReferenceExtractor
  module Internal
    extend ActiveSupport::Autoload

    autoload :AssociationInspector
    autoload :AstReferenceExtractor
    autoload :ConstNodeInspector
    autoload :ConstantDiscovery
    autoload :Extractor
    autoload :Node
    autoload :NodeHelpers
    autoload :ParsedConstantDefinitions
    autoload :Parsers
    autoload :UnresolvedReference
  end
end
