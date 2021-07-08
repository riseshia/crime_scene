# frozen_string_literal: true

require "test_helper"

module CrimeScene
  class ConstantLocationGuessorTest < Minitest::Test
    def test_simple_case
      const_name = "User"
      candidates = ["app/models/user.rb"]
      known_constants = {}

      expected_path = candidates.first
      actual_path = ConstantLocationGuessor.call(const_name, candidates, known_constants)
      assert_equal expected_path, actual_path
    end

    def test_several_candidates
      const_name = "User::STATUS"
      candidates = ["app/models/user.rb", "app/models/user/status.rb"]
      known_constants = {}

      expected_path = candidates.last
      actual_path = ConstantLocationGuessor.call(const_name, candidates, known_constants)
      assert_equal expected_path, actual_path
    end

    def test_nested_const
      const_name = "User::STATUS"
      candidates = ["app/models/user.rb"]
      known_constants = {}

      expected_path = candidates.first
      actual_path = ConstantLocationGuessor.call(const_name, candidates, known_constants)
      assert_equal expected_path, actual_path
    end

    def test_known_const
      const_name = "User::STATUS"
      candidates = []
      known_constants = { "User" => "app/models/user.rb" }

      expected_path = known_constants.values.first
      actual_path = ConstantLocationGuessor.call(const_name, candidates, known_constants)
      assert_equal expected_path, actual_path
    end
  end
end
