# frozen_string_literal: true

require "find"
require "set"

module CrimeScene
  # Treat package configuration from config file
  class PackageConfig
    def initialize(config_hash, dv_config)
      # Normalize data
      @name = config_hash.fetch(:name)
      @include_paths = config_hash.fetch(:include_paths)
      @recursive_include = config_hash.fetch(:recursive_include, false)
      @exclude_paths = dv_config.exclude_paths
    end

    def build_package
      Package.new(
        name: @name,
        include_paths: normalized_include_paths,
        exclude_paths: @exclude_paths,
        recursive_include: @recursive_include
      )
    end

    private def normalized_include_paths
      @include_paths.map { |ip| append_slash_if_needed(ip) }.sort.reverse
    end

    private def append_slash_if_needed(path)
      if File.directory?(path) && !path.end_with?("/")
        "#{path}/"
      else
        path
      end
    end
  end
end
