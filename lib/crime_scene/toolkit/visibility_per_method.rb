# frozen_string_literal: true

require "parser/current"
require "find"

module CrimeScene
  module Toolkit
    module VisibilityPerMethod # rubocop:disable Style/Documentation
      module_function

      # Make all method definition has visibility explicit
      # except public method from file.
      #
      # @option helper_paths [Array<String>]
      # @option target_helper_path [String]
      # @option rewrite [TrueClass | FalseClass]
      #
      # @return [nil]
      #
      # @example Execute with file
      # VisibilityPerMethod.execute(
      #   target_file_path: "app/helpers/user_helper.rb",
      #   rewrite: true
      # )
      def execute(
        target_helper_path:,
        rewrite: false
      )
        source_code = File.read(target_helper_path)
        new_source_code = process(source_code)

        if rewrite
          File.write(target_helper_path, new_source_code)
        else
          puts new_source_code
        end

        nil
      end

      # @param source_code [String]
      # @return [String]
      def process(source_code)
        ast = Parser::CurrentRuby.parse(source_code)
        buffer = Parser::Source::Buffer.new("(add_visibility_to_method)", source: source_code)
        rewriter = AddVisibilityToMethod.new
        rewriter.rewrite(buffer, ast)
      end

      class AddVisibilityToMethod < Parser::TreeRewriter # rubocop:disable Style/Documentation
        def initialize
          super
          @scopes = []
          @visibility = :public
        end

        def on_send(node)
          receiver, method_name, target = node.children
          return unless receiver.nil?
          return unless target.nil?

          case method_name
          when :private
            @visibility = :private
            remove_line(node)
          when :protected
            @visibility = :protected
            remove_line(node)
          when :public
            @visibility = :public
          end
        end

        def on_def(node)
          return if @visibility == :public

          insert_before(node.location.expression.begin, "#{@visibility} ")
        end

        private def remove_line(node)
          range = node.location.expression
          diff = range.source_line.size - range.source.size
          remove(range.adjust(begin_pos: -(diff + 1), end_pos: 0))
        end
      end
    end
  end
end
