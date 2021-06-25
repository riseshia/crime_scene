# frozen_string_literal: true

require "test_helper"

module Oni
  class AnalyzerTest < Minitest::Test
    def test_extract_constant_declarations_with_empty_code
      source_code = ""
      expected_constants = []
      actual_constants = Analyzer.analyze_ruby(source_code).collected_constants
      assert_equal expected_constants, actual_constants
    end

    def test_extract_constant_declarations_with_root_constants
      source_code = <<~EOS
    class User
      def initialize
      end
    end
    module UserHelper
      def name(user)
        user.name
      end
    end
      EOS
      expected_constants = %w[User UserHelper]
      actual_constants = Analyzer.analyze_ruby(source_code).collected_constants
      assert_equal expected_constants, actual_constants
    end

    def test_extract_constant_declarations_with_full_qualified_constants
      source_code = <<~EOS
    class MyApp::User
      def initialize
      end
    end
    module MyApp::View::UserHelper
      def name(user)
        user.name
      end
    end
      EOS
      expected_constants = %w[MyApp::User MyApp::View::UserHelper]
      actual_constants = Analyzer.analyze_ruby(source_code).collected_constants
      assert_equal expected_constants, actual_constants
    end

    def test_extract_constant_declarations_with_nested_constants
      source_code = <<~EOS
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
      EOS
      expected_constants = %w[MyApp MyApp::User MyApp::View MyApp::View::UserHelper]
      actual_constants = Analyzer.analyze_ruby(source_code).collected_constants
      assert_equal expected_constants, actual_constants
    end

    def test_extract_constant_declarations_with_inherited_class
      source_code = <<~EOS
    class User < BaseClass
      def initialize
      end
    end
      EOS
      expected_constants = %w[User]
      actual_constants = Analyzer.analyze_ruby(source_code).collected_constants
      assert_equal expected_constants, actual_constants
    end

    def test_extract_constant_declarations_with_open_self
      source_code = <<~EOS
    class User
      def initialize
      end

      class << self
        def cls_method
        end
      end
    end
      EOS
      expected_constants = %w[User]
      actual_constants = Analyzer.analyze_ruby(source_code).collected_constants
      assert_equal expected_constants, actual_constants
    end

    def test_extract_constant_references
      source_code = <<~EOS
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
      EOS
      expected_references = {
        "User" => ["Page", "Comment", "MyApp::CommentFilter::Accepted"],
        "UserHelper" => ["User"],
      }
      %w[Page Comment MyApp::CommentFilter::Accepted]
      actual_references = Analyzer.analyze_ruby(source_code).collected_references
      assert_equal expected_references, actual_references
    end
  end
end
