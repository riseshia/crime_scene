# frozen_string_literal: true

require "yaml"

module CrimeScene
  # Detemine source location of constant
  module ConstantLocationGuessor
    class << self
      def call(const_name, candidates)
        const_chains = const_name.split("::")

        loop do
          try = const_chains.join("::")
          path_suffix_candidate = ConstantPathResolver.resolve(try)

          target_path = candidates.find { |path| path.end_with?(path_suffix_candidate) }
          return target_path if target_path

          const_chains.pop
          break if const_chains.empty?
        end

        warn "'#{const_name}' fails to resolve path. candidate was:"
        candidates.each do |cand|
          warn "- #{cand}"
        end
        nil
      end
    end
  end
end
