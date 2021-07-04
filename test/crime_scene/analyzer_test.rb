# frozen_string_literal: true

require "test_helper"

module CrimeScene
  class AnalyzerTest < Minitest::Test
    def test_extract_constant_declarations_with_empty_code
      path = "user.rb"
      source_code = ""
      expected_constants = []
      actual_constants = Analyzer.analyze_ruby(path, source_code).collected_constants
      assert_equal expected_constants, actual_constants
    end

    def test_extract_constant_declarations_with_root_constants
      path = "user.rb"
      source_code = <<~TEST_CODE
        class User
          def initialize
          end
        end
        module UserHelper
          def name(user)
            user.name
          end
        end
      TEST_CODE
      expected_constants = %w[User UserHelper]
      actual_constants = Analyzer.analyze_ruby(path, source_code).collected_constants
      assert_equal expected_constants, actual_constants
    end

    def test_extract_constant_declarations_with_full_qualified_constants
      path = "user.rb"
      source_code = <<~TEST_CODE
        class MyApp::User
          def initialize
          end
        end
        module MyApp::View::UserHelper
          def name(user)
            user.name
          end
        end
      TEST_CODE
      expected_constants = %w[MyApp::User MyApp::View::UserHelper]
      actual_constants = Analyzer.analyze_ruby(path, source_code).collected_constants
      assert_equal expected_constants, actual_constants
    end

    def test_extract_constant_declarations_with_nested_constants
      path = "user.rb"
      source_code = <<~TEST_CODE
        module MyApp
          class User
            def initialize
            end
          end
        end
        module MyApp
          class View
            module UserHelper
              def name(user)
                user.name
              end
            end
          end
        end
      TEST_CODE
      expected_constants = %w[MyApp MyApp::User MyApp::View MyApp::View::UserHelper]
      actual_constants = Analyzer.analyze_ruby(path, source_code).collected_constants
      assert_equal expected_constants, actual_constants
    end

    def test_extract_constant_declarations_with_inherited_class
      path = "user.rb"
      source_code = <<~TEST_CODE
        class User < BaseClass
          def initialize
          end
        end
      TEST_CODE
      expected_constants = %w[User]
      actual_constants = Analyzer.analyze_ruby(path, source_code).collected_constants
      assert_equal expected_constants, actual_constants
    end

    def test_extract_constant_declarations_with_open_self
      path = "user.rb"
      source_code = <<~TEST_CODE
        class User
          def initialize
          end

          class << self
            def cls_method
            end
          end
        end
      TEST_CODE
      expected_constants = %w[User]
      actual_constants = Analyzer.analyze_ruby(path, source_code).collected_constants
      assert_equal expected_constants, actual_constants
    end

    def test_extract_constant_references
      path = "user.rb"
      source_code = <<~TEST_CODE
        class User
          def initialize
          end

          def pages
            Page.where(user_id: @id)
          end

          class << self
            def accepted_comments
              all_comments = Comment.all
              MyApp::CommentFilter::Accepted.execute(all_comments)
            end
          end
        end

        module UserHelper
          def render
            User.all
          end
        end
      TEST_CODE
      expected_references = {
        "User" => ["Page", "Comment", "MyApp::CommentFilter::Accepted"],
        "UserHelper" => ["User"]
      }
      actual_references = Analyzer.analyze_ruby(path, source_code).collected_references
      assert_equal expected_references, actual_references
    end

    def test_extract_reference_with_inherited_class
      path = "user.rb"
      source_code = <<~TEST_CODE
        class User < BaseClass
          def initialize
          end
        end
      TEST_CODE
      expected_references = {
        "" => ["BaseClass"]
      }
      actual_references = Analyzer.analyze_ruby(path, source_code).collected_references
      assert_equal expected_references, actual_references
    end

    def test_analyze_erb
      path = "users/index.html.erb"
      source_code = <<~TEST_CODE
        <h1>Users</h1>
        <%# This is just a comment. %>
        <% User.all.each do |user| -%>
        - <%= user.name %>
        - <%= link_to 'Show', user %>
        <% end %>
        <% post = Post.last %>
        <%= link_to 'Newest post', post %>
        <%= "plain" %> <%= "text" %>
        <%= form_for :diary,
            :remote => true do |f| %>
        <% end %>
      TEST_CODE

      expected_references = { path => %w[User Post] }
      actual_references = Analyzer.analyze_erb(path, source_code).collected_references
      assert_equal expected_references, actual_references
    end

    def test_analyze_haml
      path = "users/index.html.haml"
      source_code = <<~TEST_CODE
        %h1 Users
        -# This is just a comment.
        - @users.each do |user|
          = user.name
          = link_to 'Show', user
        - post = Post.last
        = link_to 'Newest post', post

        - (1..2).each do |i|
          -# This is NOT A COMMENT.
          %p{ :id => "Comment_\#{i}"} \#{User.find(i)}
      TEST_CODE

      expected_references = { path => %w[Post User] }
      actual_references = Analyzer.analyze_haml(path, source_code).collected_references
      assert_equal expected_references, actual_references
    end
  end
end
