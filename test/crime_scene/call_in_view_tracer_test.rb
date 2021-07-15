# frozen_string_literal: true

require "test_helper"

module CrimeScene
  class CallInViewTracerTest < Minitest::Test
    def test_call
      results = CallInViewTracer.call("target_app/app/views/users/")

      expected_map = {
        "target_app/app/views/users/_form.html.erb" => %w[form_with user pluralize],
        "target_app/app/views/users/edit.html.erb" => %w[render link_to users_path],
        "target_app/app/views/users/index.html.erb" => %w[notice format_name link_to edit_user_path new_user_path],
        "target_app/app/views/users/new.html.erb" => %w[render link_to users_path],
        "target_app/app/views/users/show.html.erb" => %w[notice link_to edit_user_path users_path]
      }

      assert_equal(expected_map, results)
    end
  end
end
