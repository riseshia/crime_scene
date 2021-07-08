# frozen_string_literal: true

require "test_helper"

module CrimeScene
  class DependencyVisualizerTest < Minitest::Test
    def test_call
      packages = DependencyVisualizer.call("target_app/packages.yml")
      actual_map = packages.each_with_object({}) do |package, obj|
        obj[package.name] = package.depend_package_names
      end

      expected_map = {
        "TargetApp" => %w[UnknownExternalPackage],
        "Lib" => %w[UnknownExternalPackage],
        "Top" => %w[Post TargetApp],
        "User" => %w[Comment Post TargetApp],
        "Post" => %w[Comment Lib TargetApp User],
        "Comment" => %w[Post TargetApp User]
      }

      assert_equal(expected_map, actual_map)
    end
  end
end
