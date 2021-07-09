# frozen_string_literal: true

require "find"
require "set"

module CrimeScene
  # Find out concrete file path of package
  module FilepathScanner
    ALLOWED_EXTS = %w[.rb .erb .haml].freeze

    module_function def call( # rubocop:disable Metrics/PerceivedComplexity
      target_paths,
      exclude_path_regexps = nil,
      recursive_scan: false
    )
      matched = Set.new

      target_paths.each do |include_path|
        Find.find(include_path) do |target_path|
          next if File.directory?(target_path)
          next unless ALLOWED_EXTS.include?(File.extname(target_path))
          next if exclude_path_regexps && exclude_path_regexps.match?(target_path)

          # Don't match file in sud-dir when recursive_scan is false
          rel_path = target_path[include_path.size..]
          next if !recursive_scan && rel_path.include?("/")

          matched << target_path
        end
      end

      matched
    end
  end
end
