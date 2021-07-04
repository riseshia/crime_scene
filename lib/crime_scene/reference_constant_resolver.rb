# frozen_string_literal: true

module CrimeScene
  # Find qualified_name of referenced constant
  module ReferenceConstantResolver
    class << self
      def call(scope_name, const_name, all_consts)
        tokens = scope_name.split("::")
        loop do
          try = [*tokens, const_name].join("::")
          return try if all_consts.member?(try)

          tokens.pop
          break if tokens.empty?
        end

        const_name
      end

      def generate_missing_modules(consts)
        consts.each_with_object(Set.new) do |const_name, result|
          tokens = const_name.split("::")
          loop do
            result.add(tokens.join("::"))
            tokens.pop
            break if tokens.empty?
          end
        end
      end
    end
  end
end
