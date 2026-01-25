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

          assert_kind_of(Prism::ProgramNode, node)
        end

        test "#call returns node with valid javascript file" do
          node = File.open(fixture_path("javascript_valid.erb"), "r") do |fixture|
            Erb.new.call(io: fixture)
          end

          # Files with no Ruby code return an empty ProgramNode
          assert_kind_of(Prism::ProgramNode, node)
          # The statements body should be empty
          assert_equal(0, node.statements.body.length)
        end

        test "#call extracts and parses ruby code from erb" do
          ast = File.open(fixture_path("simple_ruby.erb"), "r") do |fixture|
            Erb.new.call(io: fixture)
          end

          assert_kind_of(Prism::ProgramNode, ast)

          # The AST should contain the variable assignment
          assignment_nodes = find_nodes_by_class(ast, Prism::LocalVariableWriteNode)
          assert_equal(1, assignment_nodes.length)
          assert_equal(:user_name, assignment_nodes.first.name)

          # The AST should contain the method call to upcase
          call_nodes = find_nodes_by_class(ast, Prism::CallNode)
          upcase_node = call_nodes.find { |node| node.name == :upcase }
          refute_nil(upcase_node, "Expected to find :upcase method call in AST")

          # The AST should contain the if statement
          if_nodes = find_nodes_by_class(ast, Prism::IfNode)
          assert_equal(1, if_nodes.length)
        end

        test "#call raises parse error for invalid ruby syntax" do
          file_path = fixture_path("invalid.erb")

          exc = assert_raises(ParseError) do
            File.open(file_path, "r") do |fixture|
              Erb.new.call(io: fixture, file_path: file_path)
            end
          end

          # Prism error messages may differ from Parser gem
          assert exc.result.message.length > 0
          assert_equal(file_path, exc.result.file)
        end

        private

        def fixture_path(name)
          File.join("test", "fixtures", "formats", "erb", name)
        end

        def find_nodes_by_class(node, klass)
          results = []
          visit_nodes(node) do |n|
            results << n if n.is_a?(klass)
          end
          results
        end

        def visit_nodes(node, &block)
          return unless node.respond_to?(:child_nodes)

          yield node

          node.child_nodes.compact.each do |child|
            visit_nodes(child, &block)
          end
        end
      end
    end
  end
end
