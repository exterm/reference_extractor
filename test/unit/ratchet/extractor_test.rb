# frozen_string_literal: true

require "test_helper"

module Ratchet
  class ExtractorTest < Minitest::Test
    include RailsApplicationFixtureHelper

    def setup
      setup_application_fixture
      use_template(:skeleton)

      @extractor = Ratchet::Extractor.new(
        autoloaders: Rails.autoloaders,
        root_path: app_dir
      )
    end

    def teardown
      teardown_application_fixture
    end

    test "references_from_string extracts constant references" do
      snippet = "Order.find(1)"

      references = @extractor.references_from_string(snippet)

      assert_equal 1, references.count

      reference = references.first
      assert_equal "::Order", reference.constant.name
      assert_equal "components/sales/app/models/order.rb", reference.constant.location.to_s
      assert_equal "<snippet>", reference.relative_path
    end

    test "references_from_string handles invalid syntax gracefully" do
      snippet = "def broken syntax"

      assert_raises(Parsers::ParseError) do
        @extractor.references_from_string(snippet)
      end
    end

    test "references_from_file extracts constant references from Ruby file" do
      file_content = <<~RUBY
        class MyClass
          def process
            Order.find(1)
            Sales::Entry.new
          end
        end
      RUBY

      file_path = "test_file.rb"
      write_app_file(file_path, file_content)

      references = @extractor.references_from_file(file_path)

      assert_equal 2, references.count

      constant_names = references.map { |r| r.constant.name }.sort
      assert_equal ["::Order", "::Sales::Entry"], constant_names

      # Verify relative path is set correctly
      assert_equal "test_file.rb", references.first.relative_path
    end

    test "references_from_file handles absolute paths" do
      file_content = "Order.find(1)"
      file_path = "test_file.rb"
      write_app_file(file_path, file_content)

      absolute_path = to_app_path(file_path)
      references = @extractor.references_from_file(absolute_path)

      assert_equal 1, references.count
      assert_equal "::Order", references.first.constant.name
    end

    test "references_from_file returns empty array for non-existent file" do
      references = @extractor.references_from_file("non_existent.rb")

      assert_empty references
    end

    test "references_from_file handles parse errors gracefully" do
      file_content = "def broken syntax"
      file_path = "broken.rb"
      write_app_file(file_path, file_content)

      assert_raises(Parsers::ParseError) do
        @extractor.references_from_file(file_path)
      end
    end

    test "references_from_file handles ERB files" do
      file_content = "<%= Order.find(1) %>"
      file_path = "test_file.html.erb"
      write_app_file(file_path, file_content)

      references = @extractor.references_from_file(file_path)

      assert_equal 1, references.count
      assert_equal "::Order", references.first.constant.name
    end

    test "references_from_file ignores references to the same file" do
      file_path = "components/sales/app/models/order.rb"
      file_content = <<~RUBY
        class Order
          def self_reference
            Order
          end
        end
      RUBY

      write_app_file(file_path, file_content)

      references = @extractor.references_from_file(file_path)

      assert_empty references
    end
  end
end
