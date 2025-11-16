# frozen_string_literal: true

require "test_helper"

module ReferenceExtractor
  module Internal
    module Parsers
      class ErbTest < Minitest::Test
        test "#call returns node with valid file" do
          node = File.open(fixture_path("valid.erb"), "r") do |fixture|
            Erb.new.call(io: fixture)
          end

          assert_kind_of(::AST::Node, node)
        end

        test "#call returns node with valid javascript file" do
          node = File.open(fixture_path("javascript_valid.erb"), "r") do |fixture|
            Erb.new.call(io: fixture)
          end

          assert_kind_of(NilClass, node)
        end

        test "#call extracts and parses ruby code from erb" do
          ast = File.open(fixture_path("simple_ruby.erb"), "r") do |fixture|
            Erb.new.call(io: fixture)
          end

          assert_kind_of(::AST::Node, ast)

          # The AST should contain the variable assignment
          assignment_nodes = find_nodes_by_type(ast, :lvasgn)
          assert_equal(1, assignment_nodes.length)
          assert_equal(:user_name, assignment_nodes.first.children[0])

          # The AST should contain the method call to upcase
          send_nodes = find_nodes_by_type(ast, :send)
          upcase_node = send_nodes.find { |node| node.children[1] == :upcase }
          refute_nil(upcase_node, "Expected to find :upcase method call in AST")

          # The AST should contain the if statement
          if_nodes = find_nodes_by_type(ast, :if)
          assert_equal(1, if_nodes.length)
        end

        test "#call raises parse error for invalid ruby syntax" do
          file_path = fixture_path("invalid.erb")

          exc = assert_raises(ParseError) do
            File.open(file_path, "r") do |fixture|
              Erb.new.call(io: fixture, file_path: file_path)
            end
          end

          assert_match(/Syntax error/, exc.result.message)
          assert_equal(file_path, exc.result.file)
        end

        private

        def fixture_path(name)
          File.join("test", "fixtures", "formats", "erb", name)
        end

        def find_nodes_by_type(node, type)
          return [] unless node.is_a?(::AST::Node)

          results = []
          results << node if node.type == type

          node.children.each do |child|
            results.concat(find_nodes_by_type(child, type))
          end

          results
        end
      end
    end
  end
end
