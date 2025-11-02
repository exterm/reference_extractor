# frozen_string_literal: true

module Ratchet
  # A constant reference from one file to another.
  Reference = Struct.new(
    :relative_path,
    :constant,
    :source_location,
    keyword_init: true
  )
end
