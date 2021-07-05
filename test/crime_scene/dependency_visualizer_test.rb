# frozen_string_literal: true

require "test_helper"

module CrimeScene
  class DependencyVisualizerTest < Minitest::Test
    def test_call
      actual_map = DependencyVisualizer.call("target_app/packages.yml")
      expected_map = {
        "TargetApp" => ["UnknownPackage"],
        "Top" => %w[Post TargetApp],
        "User" => %w[Comment Post TargetApp],
        "Post" => %w[Comment TargetApp User],
        "Comment" => %w[Post TargetApp User]
      }

      assert_equal(expected_map, actual_map)
    end
  end
end
