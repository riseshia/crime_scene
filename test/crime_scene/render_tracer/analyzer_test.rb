# frozen_string_literal: true

require "test_helper"

module CrimeScene
  module RenderTracer
    class AnalyzerTest < Minitest::Test
      def test_extract_defined_methodns_with_empty_code
        path = "users_helper.rb"
        source_code = ""
        result = Analyzer.analyze_ruby(path, source_code)
        assert_equal [], result.normal_views
        assert_equal [], result.partial_views
        assert_equal [], result.layouts
      end

      def test_extract_render
        path = "users_helper.rb"
        source_code = <<~TEST_CODE
          module UsersHelper
            def page_render(user)
              render "simple"
              render :simple_sym
              render partial: "partial_view1", layout: "layout1"
              render "shared/view", layout: false
              render "shared/\#{somevar}"
              render somevar
              render @somevar
              render partial: @var_for_partial, layout: @var_for_layout
            end
          end
        TEST_CODE

        result = Analyzer.analyze_ruby(path, source_code)
        assert_equal %W[
          simple
          simple_sym
          shared/view
          dstr:shared/\#{somevar}
          send:somevar ivar:@somevar
        ], result.normal_views
        assert_equal %w[partial_view1 ivar:@var_for_partial], result.partial_views
        assert_equal %w[layout1 ivar:@var_for_layout], result.layouts
      end

      def test_analyze_erb
        path = "users/index.html.erb"
        source_code = <<~TEST_CODE
          <h1>Users</h1>
          <%# This is just a comment. %>
          <% User.all.each do |user| -%>
          - <%= user_name(user.name) %>
          - <%= render 'simple', user: user %>
          - <%= render 'shared/user', user: user %>
          - <%= render partial: 'partial',
                        user: user, layout: 'special_layout' %>
          <% end %>
          <% post = Post.last %>
          <%= link_to 'Newest post', post %>
          <%= "plain" %> <%= "text" %>
          <%= form_for :diary,
              :remote => true do |f| %>
          <% end %>
        TEST_CODE

        result = Analyzer.analyze_erb(path, source_code)
        assert_equal %w[simple shared/user], result.normal_views
        assert_equal %w[partial], result.partial_views
        assert_equal %w[special_layout], result.layouts
      end

      def test_analyze_haml
        path = "users/index.html.haml"
        source_code = <<~TEST_CODE
          %h1 Users
          -# This is just a comment.
          - @users.each do |user|
            = user_name(user.name)
            = link_to 'Show', user
            = render 'simple', user: user
            = render 'shared/user', user: user
            = render partial: 'partial',
                     user: user, layout: 'special_layout'
          - post = Post.last
          = link_to 'Newest post', post

          - (1..2).each do |i|
            -# This is NOT A COMMENT.
            %p{ :id => "Comment_\#{i}"} \#{User.find(i)}
        TEST_CODE

        result = Analyzer.analyze_haml(path, source_code)
        assert_equal %w[simple shared/user], result.normal_views
        assert_equal %w[partial], result.partial_views
        assert_equal %w[special_layout], result.layouts
      end
    end
  end
end
