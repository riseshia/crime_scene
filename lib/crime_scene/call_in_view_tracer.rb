# frozen_string_literal: true

require "find"

module CrimeScene
  # Find out call in helpers / views
  module CallInViewTracer
    module_function

    def call(base_path)
      merged = {}

      Find.find(base_path) do |path|
        next if File.directory?(path)

        result =
          case File.extname(path)
          when ".rb"
            Analyzer.analyze_ruby(path, File.read(path))
          when ".haml"
            Analyzer.analyze_haml(path, File.read(path))
          when ".erb"
            Analyzer.analyze_erb(path, File.read(path))
          end

        next if result.nil?

        merged.merge!(result.called_methods)
      end

      merged
    end
  end
end
