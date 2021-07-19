# frozen_string_literal: true

require "parser/current"

module CrimeScene
  module RenderTracer
    class AstProcessor # rubocop:disable Style/Documentation
      include AST::Processor::Mixin

      def initialize
        @partial_views = Set.new
        @normal_views = Set.new
        @layouts = Set.new
      end

      def add_partial_view(view_path)
        @partial_views.add(view_path)
      end

      def add_normal_view(view_path)
        @normal_views.add(view_path)
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

      RECORD_TYPE = %i[str dstr ivar send]
      def record_render(node)
        args = node.children[2..]
        return if args.empty?

        args.each do |arg|
          if RECORD_TYPE.include?(arg.type)
            name = format_name(arg)
            add_normal_view(name)
          end

          next unless arg.type == :hash

          if partial = fetch_value_from_hash(arg, "partial")
            if RECORD_TYPE.include?(partial.type)
              name = format_name(partial)
              add_partial_view(name)
            end
          end

          if layout = fetch_value_from_hash(arg, "layout")
            if RECORD_TYPE.include?(layout.type)
              name = format_name(layout)
              add_layout(name)
            end
          end
        end

        nil
      end

      def format_name(node)
        case node.type
        when :str
          node.children.first
        when :dstr
          "dstr:#{node.location.expression.source[1..-2]}"
        when :ivar
          "ivar:#{node.location.expression.source}"
        when :send
          "send:#{node.location.expression.source}"
        else
          raise "Unsupported type #{node.type}"
        end
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
          normal_views: @normal_views.to_a,
          layouts: @layouts.to_a
        }
      end
    end
  end
end
