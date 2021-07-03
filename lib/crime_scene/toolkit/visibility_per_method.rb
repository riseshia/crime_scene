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
      # @option target_file_path [String]
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
        target_file_path:,
        rewrite: false
      )
        source_code = File.read(target_file_path)
        new_source_code = process(source_code)

        if rewrite
          File.write(target_file_path, new_source_code)
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
          @scopes = []
          @visibilites = []
          super
        end

        def on_class(node)
          push_scope
          node.children[1..].each { |n| process(n) if n.is_a? Parser::AST::Node }
          pop_scope
        end

        def on_sclass(node)
          push_scope
          node.children[1..].each { |n| process(n) if n.is_a? Parser::AST::Node }
          pop_scope
        end

        def on_module(node)
          push_scope
          node.children[1..].each { |n| process(n) if n.is_a? Parser::AST::Node }
          pop_scope
        end

        def on_block(node)
          struct_def = struct_def?(node)
          push_scope if struct_def
          node.children.each { |n| process(n) if n.is_a? Parser::AST::Node }
          pop_scope if struct_def
        end

        private def struct_def?(node) # rubocop:disable Metrics/PerceivedComplexity
          return false unless node.type == :block

          struct_new = node.children.first

          return false unless struct_new&.type == :send

          receiver, method_name = struct_new.children
          if method_name == :new && receiver&.type == :const && receiver.children == [nil, :Struct]
            true
          else
            false
          end
        end

        TARGET_METHOD = %i[public protected private].freeze
        def on_send(node)
          receiver, method_name, target = node.children
          return unless TARGET_METHOD.include?(method_name)
          return unless receiver.nil?

          if target&.type == :sym
            # symbol visibility used.
            remove_line(node)
            return
          end
          if target&.type == :def
            # Inline visibility used.
            return
          end

          case method_name
          when :private
            update_current_visibility(:private)
            remove_line(node)
          when :protected
            update_current_visibility(:protected)
            remove_line(node)
          when :public
            update_current_visibility(:public)
          end
        end

        def on_def(node)
          method_visibility = try_retrieve_method_visibility_from_next_line(node) || current_visibility
          return if method_visibility == :public

          insert_before(node.location.expression.begin, "#{method_visibility} ")
        end

        private def try_retrieve_method_visibility_from_next_line(node)
          end_lineno = node.location.end.line
          next_line = fetch_next_line_from_buffer(end_lineno).strip

          if next_line.start_with?("private :") then :private
          elsif next_line.start_with?("protected :") then :protected
          elsif next_line.start_with?("public :") then :public
          end
        end

        private def fetch_next_line_from_buffer(lineno)
          idx = lineno

          loop do
            idx += 1
            idx_line = source_buffer.source_line(idx)
            return idx_line if idx_line.strip.size.positive?
          rescue Parser::Source::Buffer::IndexError => e
            raise e
          end
        end

        private def source_buffer
          @source_rewriter.source_buffer
        end

        private def remove_line(node)
          lineno = node.location.line
          begin_pos = source_buffer.line_range(lineno - 1).end_pos
          range = source_buffer.line_range(lineno).with(begin_pos: begin_pos)
          remove(range)
        end

        private def current_visibility
          @visibilites.last
        end
        private def update_current_visibility(value)
          @visibilites[-1] = value
        end
        private def push_scope
          @visibilites << :public
        end
        private def pop_scope
          @visibilites.pop
        end
      end
    end
  end
end
