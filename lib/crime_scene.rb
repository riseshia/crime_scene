# frozen_string_literal: true

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup

require "json"
require "set"
require "find"

module CrimeScene # rubocop:disable Style/Documentation
  module_function

  def package_analyze( # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
    package_name:,
    package_path:,
    exclude_paths: ["/spec/"],
    include_exts: [".rb"]
  )
    exclude_path_regexp = Regexp.union(exclude_paths)
    aggregated = {
      package_name: package_name,
      constants: {},
      references: {}
    }
    ambiguous_constants = {}

    Find.find(package_path) do |path|
      next if path.match?(exclude_path_regexp)
      next unless include_exts.include?(File.extname(path))

      result = Analyzer.analyze_file(path)
      result.collected_constants.each do |const_name|
        ambiguous_constants[const_name] ||= Set.new
        ambiguous_constants[const_name].add(path)
      end
      result.collected_references.each do |const_name, refered_consts|
        aggregated[:references][const_name] ||= Set.new
        aggregated[:references][const_name].merge(refered_consts)
      end
    end

    constants = {}
    ambiguous_constants.each do |const_name, paths|
      if paths.size == 1
        constants[const_name] = paths.first
      else
        path_suffix_candidate = ConstantPathResolver.resolve(const_name)
        target_path = paths.find { |path| path.end_with?(path_suffix_candidate) }

        if target_path
          constants[const_name] = target_path
        else
          warn "'#{const_name}' fails to resolve path."
        end
      end
    end
    aggregated[:constants] = constants
    aggregated[:references].transform_values!(&:to_a)

    File.write("#{package_name}.json", JSON.dump(aggregated))
  end
end
