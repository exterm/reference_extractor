# frozen_string_literal: true

require "pathname"

require "ratchet"

require "minitest/autorun"
require "mocha/minitest"

require "support/ratchet/application_fixture_helper"
require "support/rails_application_fixture_helper"

require "support/test_macro"

Minitest::Test.extend(TestMacro)
