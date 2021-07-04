# frozen_string_literal: true

require "test_helper"

module CrimeScene
  class ReferenceConstantResolverTest < Minitest::Test
    def test_call
      expected_name = "MyApp::User"
      actual_name = ReferenceConstantResolver.call("MyApp", "User", Set.new(["MyApp", "MyApp::User", "User"]))
      assert_equal expected_name, actual_name
    end

    def test_generate_missing
      expected_consts = %w[MyApp::Model MyApp User]
      actual_consts = ReferenceConstantResolver.generate_missing_modules(Set.new(%w[MyApp::Model User]))
      assert_equal expected_consts, actual_consts.to_a
    end
  end
end
