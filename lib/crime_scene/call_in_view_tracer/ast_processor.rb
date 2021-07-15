# frozen_string_literal: true

require "parser/current"

module CrimeScene
  module CallInViewTracer
    class AstProcessor # rubocop:disable Style/Documentation
      include AST::Processor::Mixin

      def initialize
        @called_methods = {}
        @scopes = []
      end

      def current_scope
        @scopes.join("::")
      end

      def add_called_methods(method_name)
        @called_methods[current_scope] ||= Set.new
        @called_methods[current_scope].add(method_name)
      end

      def build_const(const_node)
        target_node = const_node
        const_names = []
        loop do
          child_node, const_name = target_node.children
          const_names << const_name.to_s
          if child_node&.type == :const # rubocop:disable Style/GuardClause
            target_node = child_node
          else
            break
          end
        end
        const_names.reverse.join("::")
      end

      def handler_missing(node)
        node.children.each { |n| process(n) if n.is_a? Parser::AST::Node }
        nil
      end

      def on_class(node)
        const_name_in_scope = build_const(node.children[0])
        @scopes << const_name_in_scope
        node.children[2..].each { |n| process(n) if n.is_a? Parser::AST::Node }
        @scopes.pop
        nil
      end

      def on_module(node)
        const_name_in_scope = build_const(node.children[0])
        @scopes << const_name_in_scope
        node.children[1..].each { |n| process(n) if n.is_a? Parser::AST::Node }
        @scopes.pop
        nil
      end

      def on_send(node)
        receiver, method_name, _target = node.children

        add_called_methods(method_name.to_s) if receiver.nil?

        node.children.each { |n| process(n) if n.is_a? Parser::AST::Node }
      end

      def fetch_value_from_hash(node, key)
        node.children.find do |pair|
          k, _v = pair.children
          k.children.first.to_s == key
        end
      end

      # Return true when success to add reference
      # @return [TrueClass | FalseClass]
      def add_value_to_reference_if_key_exist(option_node, key)
        target_opt = fetch_value_from_hash(option_node, key)

        if target_opt
          _k, v = target_opt.children
          const_name = v.children.last.to_s
          add_reference("", Inflection.constantize(const_name))
          return true
        end
        false
      end

      def result
        { called_methods: @called_methods.transform_values(&:to_a) }
      end
    end
  end
end
