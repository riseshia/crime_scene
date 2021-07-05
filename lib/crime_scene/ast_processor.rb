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

    def add_reference(scope, const_name)
      @collected_references[scope] ||= Set.new
      @collected_references[scope].add(const_name)
    end

    def add_constant(const_name)
      @collected_constant_sets.add(const_name)
    end

    def on_class(node) # rubocop:disable Metrics/AbcSize
      const_name_in_scope = build_const(node.children[0])

      full_qualified_name = qualify_const_name(const_name_in_scope)
      add_constant(full_qualified_name)

      if node.children[1]
        current_scope = @scopes.join("::")
        inherit_const_name = build_const(node.children[1])

        add_reference(current_scope, inherit_const_name)
      end

      @scopes << const_name_in_scope
      node.children[2..].each { |n| process(n) if n.is_a? Parser::AST::Node }
      @scopes.pop

      nil
    end

    def on_module(node)
      const_name_in_scope = build_const(node.children.first)
      full_qualified_name = qualify_const_name(const_name_in_scope)
      add_constant(full_qualified_name)

      @scopes << const_name_in_scope
      node.children[1..].each { |n| process(n) if n.is_a? Parser::AST::Node }
      @scopes.pop
      nil
    end

    def on_const(node)
      const_name = build_const(node)
      current_scope = @scopes.join("::")

      add_reference(current_scope, const_name)
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

    TARGET_METHOD = %i[has_many].freeze
    def on_send(node)
      _receiver, method_name, _target = node.children
      case method_name
      when :has_one, :has_many, :belongs_to
        on_rails_association_dsl(node)
      else
        node.children.each { |n| process(n) if n.is_a? Parser::AST::Node }
      end
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

    # Treat found association const as global scope
    def on_rails_association_dsl(node)
      receiver, _method_name, target, option = node.children
      return unless receiver.nil?

      if target.type == :sym && option&.type == :hash
        add_value_to_reference_if_key_exist(option, "through")

        return if add_value_to_reference_if_key_exist(option, "class_name")
      end

      if target.type == :sym
        const_name = Inflection.constantize(target.children.first.to_s)
        add_reference("", const_name)
        return
      end

      raise "Unhandled rails DSL! #{node}"
    end

    def result
      {
        collected_constants: @collected_constant_sets.to_a,
        collected_references: @collected_references.transform_values(&:to_a)
      }
    end
  end
end
