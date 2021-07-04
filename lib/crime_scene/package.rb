# frozen_string_literal: true

require "find"
require "set"

module CrimeScene
  # Package is the concept to aggregate files.
  # This is the unit of calculating dependencies.
  class Package
    attr_reader :name, :include_paths, :recursive_include, :files, :references, :constants

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
      @files = Set.new
      @references = Set.new
      @constants = Set.new
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
