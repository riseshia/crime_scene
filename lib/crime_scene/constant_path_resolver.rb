# frozen_string_literal: true

module CrimeScene
  module ConstantPathResolver # rubocop:disable Style/Documentation
    module_function

    # @return [String] const_path
    def resolve(const_name)
      const_name.gsub(/::/, "/") # rubocop:disable Style/StringConcatenation
                .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                .tr("-", "_")
                .downcase + ".rb"
    end
  end
end
