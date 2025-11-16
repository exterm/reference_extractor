module ReferenceExtractor
  class ParseError < StandardError
    attr_reader(:result)

    def initialize(result)
      super(result.message)
      @result = result
    end
  end
end
