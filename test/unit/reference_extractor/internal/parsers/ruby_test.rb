# frozen_string_literal: true

require "test_helper"

module ReferenceExtractor
  module Internal
    module Parsers
      class RubyTest < Minitest::Test
        test "#call returns node with valid file" do
          node = File.open(fixture_path("valid.rb"), "r") do |fixture|
            Ruby.new.call(io: fixture)
          end

          assert_kind_of(::AST::Node, node)
        end

        test "#call raises parse error for invalid ruby syntax" do
          file_path = fixture_path("invalid.rb")

          exc = assert_raises(ParseError) do
            File.open(file_path, "r") do |fixture|
              Ruby.new.call(io: fixture, file_path: file_path)
            end
          end

          assert_match(/Syntax error/, exc.result.message)
          assert_equal(file_path, exc.result.file)
        end

        test "#call raises parse error for invalid encoding" do
          # This tests that EncodingError is properly caught when Parser::Source::Buffer
          # validates the source encoding (buffer.source = io.read raises EncodingError)
          file_path = fixture_path("invalid_encoding.rb")

          exc = assert_raises(ParseError) do
            File.open(file_path, "r", encoding: "UTF-8") do |fixture|
              Ruby.new.call(io: fixture, file_path: file_path)
            end
          end

          assert_match(/invalid byte sequence/, exc.result.message)
          assert_equal(file_path, exc.result.file)
        end

        test "#call parses Ruby code containing invalid UTF-8 strings" do
          node = File.open(fixture_path("invalid_utf8_string.rb"), "r") do |fixture|
            Ruby.new.call(io: fixture)
          end

          assert_kind_of(::AST::Node, node)
        end

        private

        def fixture_path(name)
          File.join("test", "fixtures", "formats", "ruby", name)
        end
      end
    end
  end
end
