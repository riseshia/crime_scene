require "parser/current"

module Oni
  class AstProcessor
    include AST::Processor::Mixin

    def initialize
      @collected_constant_sets = Set.new
      @collected_references = {}
      @scopes = []
    end

    def on_class(node)
      const_name_in_scope = build_const(node.children.first)
      full_qualified_name = qualify_const_name(const_name_in_scope)
      @collected_constant_sets.add(full_qualified_name)

      @scopes << const_name_in_scope
      node.children[1..-1].each { |n| process(n) if n.is_a? Parser::AST::Node }
      @scopes.pop
      nil
    end

    def on_module(node)
      const_name_in_scope = build_const(node.children.first)
      full_qualified_name = qualify_const_name(const_name_in_scope)
      @collected_constant_sets.add(full_qualified_name)

      @scopes << const_name_in_scope
      node.children[1..-1].each { |n| process(n) if n.is_a? Parser::AST::Node }
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
        if child_node&.type == :const
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
        collected_references: @collected_references.transform_values(&:to_a),
      }
    end
  end
end
