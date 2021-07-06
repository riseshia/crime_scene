# frozen_string_literal: true

require "find"
require "set"

module CrimeScene
  # Package is the concept to aggregate files.
  # This is the unit of calculating dependencies.
  class Package
    attr_reader :name, :include_paths, :recursive_include, :files, :references, :constants
    attr_accessor :depend_package_names

    # @option name [String]
    # @option include_paths [Array<String>]
    # @option recursive_include [TrueClass | FalseClass]
    def initialize(
      name:,
      include_paths:,
      recursive_include:
    )
      @name = name
      @include_paths = Set.new(include_paths)
      @recursive_include = recursive_include

      # This will be injected.
      @files = Set.new
      @references = Set.new
      @constants = Set.new
      @depend_package_names = Set.new
    end

    def export
      {
        name: @name,
        include_paths: @include_paths,
        recursive_include: @recursive_include,
        files: @files,
        references: @references,
        constants: @constants,
        external_references: external_references,
        depend_package_names: @depend_package_names
      }
    end

    def external_references
      @references - @constants
    end

    # @param references [Set<String>]
    def add_references(references)
      @references.merge(references)
    end

    # @param constants [Set<String>]
    def add_constants(constants)
      @constants.merge(constants)
    end

    # Expand include_path to actual path with recursive_include
    # If recursive_include is true, files in sub-dir would be included.
    def load_file_path!
      @files = PackageFilepathScanner.call(self)
    end
  end
end
