# frozen_string_literal: true

require "parser/current"

module CrimeScene
  module RenderTracer
    class AstProcessor # rubocop:disable Style/Documentation
      include AST::Processor::Mixin

      def initialize
        @partial_views = Set.new
        @layouts = Set.new
      end

      def add_partial_view(view_path)
        @partial_views.add(view_path)
      end

      def add_layout(view_path)
        @layouts.add(view_path)
      end

      def handler_missing(node)
        node.children.each { |n| process(n) if n.is_a? Parser::AST::Node }
        nil
      end

      def on_send(node)
        receiver, method_name, _target = node.children

        if receiver.nil? && method_name == :render
          record_render(node)
        end
        node.children.each { |n| process(n) if n.is_a? Parser::AST::Node }
      end

      def record_render(node)
        args = node.children[2..]
        return if args.empty?

        args.each do |arg|
          if arg.type == :str
            add_partial_view(arg.children.first)
          end

          next unless arg.type == :hash

          if partial = fetch_value_from_hash(arg, "partial")
            add_partial_view(partial.children.last.to_s)
          end

          if layout = fetch_value_from_hash(arg, "layout")
            if layout.type != :false
              add_layout(layout.children.last.to_s)
            end
          end
        end

        nil
      end

      def fetch_value_from_hash(node, key)
        target = node.children.find do |pair|
          k, _v = pair.children
          k.children.first.to_s == key
        end

        target&.children&.last
      end

      def result
        {
          partial_views: @partial_views.to_a,
          layouts: @layouts.to_a
        }
      end
    end
  end
end
