# frozen_string_literal: true

require "test_helper"

module CrimeScene
  class DependencyVisualizerTest < Minitest::Test
    def test_call
      actual_map = DependencyVisualizer.call("target_app/packages.yml")
      expected_map = {
      }

      assert_equal(expected_map, actual_map)
    end
  end
end
