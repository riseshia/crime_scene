# frozen_string_literal: true

require "yaml"

module CrimeScene
  # Detemine source location of constant
  module ConstantLocationGuessor
    class << self
      def call(const_name, candidates)
        path_suffix_candidate = ConstantPathResolver.resolve(const_name)
        target_path = candidates.find { |path| path.end_with?(path_suffix_candidate) }

        if target_path
          target_path
        else
          warn "'#{const_name}' fails to resolve path."
          nil
        end
      end
    end
  end
end
