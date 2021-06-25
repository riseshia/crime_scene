# frozen_string_literal: true

require "test_helper"

module Oni
  class ConstantPathResolverTest < Minitest::Test
    def test_resolve
      expected_path = "my_app/user.rb"
      actual_path = Oni::ConstantPathResolver.resolve("MyApp::User")
      assert_equal expected_path, actual_path
    end
  end
end
