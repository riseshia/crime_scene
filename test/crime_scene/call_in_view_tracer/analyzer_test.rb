# frozen_string_literal: true

require "test_helper"

module CrimeScene
  module CallInViewTracer
    class AnalyzerTest < Minitest::Test
      def test_extract_defined_method_with_empty_code
        path = "users_helper.rb"
        source_code = ""
        results = Analyzer.analyze_ruby(path, source_code)
        assert_equal({}, results.called_methods)
      end

      def test_extract_called_method_names
        path = "admin/users_helper.rb"
        source_code = <<~TEST_CODE
          module Admin
            module UsersHelper
              def name(user)
                hoge
                PostHelper.another
              end

              def hoge
                (1..3).each do |i|
                  method_from_somewhere(i)
                end
              end
            end
          end
        TEST_CODE
        results = Analyzer.analyze_ruby(path, source_code)
        assert_equal({ "Admin::UsersHelper" => %w[hoge method_from_somewhere] }, results.called_methods)
      end

      def test_analyze_erb
        path = "users/index.html.erb"
        source_code = <<~TEST_CODE
          <h1>Users</h1>
          <%# This is just a comment. %>
          <% User.all.each do |user| -%>
          - <%= user_name(user.name) %>
          - <%= link_to 'Show', user %>
          <% end %>
          <% post = Post.last %>
          <%= link_to 'Newest post', post %>
          <%= "plain" %> <%= "text" %>
          <%= form_for :diary,
              :remote => true do |f| %>
          <% end %>
        TEST_CODE

        results = Analyzer.analyze_erb(path, source_code)
        assert_equal({
                       "users/index.html.erb" => %w[user_name link_to form_for]
                     }, results.called_methods)
      end

      def test_analyze_haml
        path = "users/index.html.haml"
        source_code = <<~TEST_CODE
          %h1 Users
          -# This is just a comment.
          - @users.each do |user|
            = user_name(user.name)
            = link_to 'Show', user
          - post = Post.last
          = link_to 'Newest post', post

          - (1..2).each do |i|
            -# This is NOT A COMMENT.
            %p{ :id => "Comment_\#{i}"} \#{User.find(i)}
        TEST_CODE

        results = Analyzer.analyze_haml(path, source_code)
        assert_equal({
                       "users/index.html.haml" => %w[user_name link_to]
                     }, results.called_methods)
      end
    end
  end
end
