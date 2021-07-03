# frozen_string_literal: true

require "parser/current"

module CrimeScene
  class AstProcessor # rubocop:disable Style/Documentation
    include AST::Processor::Mixin

    def initialize
      @collected_constant_sets = Set.new
      @collected_references = {}
      @scopes = []
    end

    def on_class(node) # rubocop:disable Metrics/AbcSize
      const_name_in_scope = build_const(node.children[0])

      full_qualified_name = qualify_const_name(const_name_in_scope)
      @collected_constant_sets.add(full_qualified_name)

      unless node.children[1].nil?
        inherit_const_name = build_const(node.children[1])
        @collected_constant_sets.add(inherit_const_name)
      end

      @scopes << const_name_in_scope
      node.children[1..].each { |n| process(n) if n.is_a? Parser::AST::Node }
      @scopes.pop
      nil
    end

    def on_module(node)
      const_name_in_scope = build_const(node.children.first)
      full_qualified_name = qualify_const_name(const_name_in_scope)
      @collected_constant_sets.add(full_qualified_name)

      @scopes << const_name_in_scope
      node.children[1..].each { |n| process(n) if n.is_a? Parser::AST::Node }
      @scopes.pop
      nil
    end

    def on_const(node)
      const_name = build_const(node)
      current_scope = @scopes.join("::")

      @collected_references[current_scope] ||= Set.new
      @collected_references[current_scope].add(const_name)
      nil
    end

    def handler_missing(node)
      node.children.each { |n| process(n) if n.is_a? Parser::AST::Node }
      nil
    end

    def qualify_const_name(name)
      (@scopes + [name]).join("::")
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

    def result
      {
        collected_constants: @collected_constant_sets.to_a,
        collected_references: @collected_references.transform_values(&:to_a)
      }
    end
  end
end
