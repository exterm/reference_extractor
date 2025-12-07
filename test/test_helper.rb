# frozen_string_literal: true

require "pathname"
require "set"

require "reference_extractor"

require "minitest/autorun"
require "mocha/minitest"

require "support/reference_extractor/application_fixture_helper"
require "support/rails_application_fixture_helper"

require "support/test_macro"

Minitest::Test.extend(TestMacro)
