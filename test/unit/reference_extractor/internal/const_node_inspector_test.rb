# frozen_string_literal: true

require "test_helper"
require "support/reference_extractor/parser_test_helper"

module ReferenceExtractor
  module Internal
    class ConstNodeInspectorTest < ActiveSupport::TestCase
      setup do
        @inspector = ConstNodeInspector.new
      end

      test "#constant_name_from_node should ignore any non-const nodes" do
        node = parse("a = 1 + 1")

        constant_name = @inspector.constant_name_from_node(node, ancestors: [])

        assert_nil constant_name
      end

      test "#constant_name_from_node should return correct name for const node" do
        node = parse("Order")

        constant_name = @inspector.constant_name_from_node(node, ancestors: [])

        assert_equal "Order", constant_name
      end

      test "#constant_name_from_node should return correct name for fully-qualified const node" do
        node = parse("::Order")

        constant_name = @inspector.constant_name_from_node(node, ancestors: [])

        assert_equal "::Order", constant_name
      end

      test "#constant_name_from_node should return correct name for compact const node" do
        node = parse("Sales::Order")

        constant_name = @inspector.constant_name_from_node(node, ancestors: [])

        assert_equal "Sales::Order", constant_name
      end

      test "#constant_name_from_node should return correct name for simple class definition" do
        parent = parse("class Order; end")
        node = parent.constant_path

        constant_name = @inspector.constant_name_from_node(node, ancestors: [parent])

        assert_equal "::Order", constant_name
      end

      test "#constant_name_from_node should return correct name for nested and compact class definition" do
        grandparent = parse("module Foo::Bar; class Sales::Order; end; end")
        parent = grandparent.body.body.first # class Sales::Order; end
        node = parent.constant_path

        constant_name = @inspector.constant_name_from_node(node, ancestors: [parent, grandparent])

        assert_equal "::Foo::Bar::Sales::Order", constant_name
      end

      test "#constant_name_from_node should gracefully return nil for dynamically namespaced constants" do
        grandparent = parse("module CsvExportSharedTests; setup do self.class::HEADERS end; end")
        # Navigate to the constant path node: self.class::HEADERS
        # module body -> call node (setup do...) -> block -> statements -> constant path
        setup_call = grandparent.body.body.first
        block_body = setup_call.block.body.body.first
        node = block_body

        constant_name = @inspector.constant_name_from_node(node, ancestors: [setup_call.block, setup_call, grandparent])

        assert_nil constant_name
      end

      private

      def parse(code)
        ParserTestHelper.parse(code)
      end
    end
  end
end
