# frozen_string_literal: true

require "find"
require "set"

module CrimeScene
  # Find out concrete file path of package
  module PackageFilepathScanner
    ALLOWED_EXTS = %w[.rb .erb .haml].freeze

    module_function def call(package)
      matched = Set.new

      package.include_paths.each do |include_path|
        Find.find(include_path) do |target_path|
          next if File.directory?(target_path)
          next unless ALLOWED_EXTS.include?(File.extname(target_path))

          # Don't match file in sud-dir when recursive_include is false
          rel_path = target_path[include_path.size..]
          next if !package.recursive_include && rel_path.include?("/")

          matched << target_path
        end
      end

      matched
    end
  end
end
