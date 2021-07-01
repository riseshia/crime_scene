# frozen_string_literal: true

require "test_helper"

module CrimeScene
  module Toolkit
    class VisibilityPerMethodTest < Minitest::Test
      def test_do_nothing
        source_code = <<~TEST_CODE
          module UserHelper
            def name(user)
              user.name
            end

            public def public_name(user)
              user.name
            end

            private def private_name(user)
              user.name
            end

            protected def protected_name(user)
              user.name
            end
          end
        TEST_CODE

        actual_code = VisibilityPerMethod.process(source_code)
        assert_equal source_code, actual_code
      end

      def test_append_visibility
        source_code = <<~TEST_CODE
          module UserHelper
            private
            def private_name(user)
              user.name
            end

            protected
            def protected_name(user)
              user.name
            end
          end
        TEST_CODE

        expected_code = <<~TEST_CODE
          module UserHelper
            private def private_name(user)
              user.name
            end

            protected def protected_name(user)
              user.name
            end
          end
        TEST_CODE
        actual_code = VisibilityPerMethod.process(source_code)
        assert_equal expected_code, actual_code
      end

      def test_replace_symbol
        source_code = <<~TEST_CODE
          module UserHelper
            def private_name(user)
              user.name
            end
            private :private_name

            def protected_name(user)
              user.name
            end
            protected :protected_name
          end
        TEST_CODE

        expected_code = <<~TEST_CODE
          module UserHelper
            private def private_name(user)
              user.name
            end

            protected def protected_name(user)
              user.name
            end
          end
        TEST_CODE
        actual_code = VisibilityPerMethod.process(source_code)
        assert_equal expected_code, actual_code
      end

      def test_nested_module_method_visibility
        source_code = <<~TEST_CODE
          module User
            private
            module UserHelper
              def public_name(user)
                user.name
              end

              private
              def private_name(user)
                user.name
              end

              protected
              def protected_name(user)
                user.name
              end
            end
          end
        TEST_CODE

        expected_code = <<~TEST_CODE
          module User
            module UserHelper
              def public_name(user)
                user.name
              end

              private def private_name(user)
                user.name
              end

              protected def protected_name(user)
                user.name
              end
            end
          end
        TEST_CODE
        actual_code = VisibilityPerMethod.process(source_code)
        assert_equal expected_code, actual_code
      end

      def test_nested_self_class_method_visibility
        source_code = <<~TEST_CODE
          class Note
            class << self
              def public_class_method
              end

              private
              def private_class_method
              end
            end

            def pub_ins_method
            end
          end
        TEST_CODE

        expected_code = <<~TEST_CODE
          class Note
            class << self
              def public_class_method
              end

              private def private_class_method
              end
            end

            def pub_ins_method
            end
          end
        TEST_CODE
        actual_code = VisibilityPerMethod.process(source_code)
        assert_equal expected_code, actual_code
      end
    end
  end
end
