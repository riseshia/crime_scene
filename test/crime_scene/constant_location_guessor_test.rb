# frozen_string_literal: true

require "test_helper"

module CrimeScene
  class ConstantLocationGuessorTest < Minitest::Test
    def test_simple_case
      const_name = "User"
      candidates = ["app/models/user.rb"]

      expected_path = candidates.first
      actual_path = ConstantLocationGuessor.call(const_name, candidates)
      assert_equal expected_path, actual_path
    end

    def test_several_candidates
      const_name = "User::STATUS"
      candidates = ["app/models/user.rb", "app/models/user/status.rb"]

      expected_path = candidates.last
      actual_path = ConstantLocationGuessor.call(const_name, candidates)
      assert_equal expected_path, actual_path
    end

    def test_nested_const
      const_name = "User::STATUS"
      candidates = ["app/models/user.rb"]

      expected_path = candidates.first
      actual_path = ConstantLocationGuessor.call(const_name, candidates)
      assert_equal expected_path, actual_path
    end
  end
end
