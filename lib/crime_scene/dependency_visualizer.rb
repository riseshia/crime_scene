# frozen_string_literal: true

require "yaml"

module CrimeScene
  # Entrypoint of Dependency calculation.
  module DependencyVisualizer
    class << self
      # @return [Hash<String, Array<String>>] { package_name => [package_name] }
      def call(packages_config_path)
        packages_config = YAML.safe_load(File.read(packages_config_path), symbolize_names: true)
        path_to_config_file = File.dirname(packages_config_path)

        packages = nil
        meta_per_file = nil
        Dir.chdir(path_to_config_file) do
          packages = load_packages(packages_config)
          all_files = aggregation_filepaths_from_package(packages)
          meta_per_file = process_asts(all_files)
        end

        append_reference_to_package(packages, meta_per_file)

        const_to_location = find_out_const_location(meta_per_file)
        append_const_location_to_package(packages, const_to_location)

        package_to_external_consts = extract_external_const(packages)

        convert_const_to_package(packages, package_to_external_consts)
      end

      def convert_const_to_package(packages, package_to_external_consts)
        const_to_package_name = {}
        packages.each do |package|
          package.constants.each do |const_name|
            const_to_package_name[const_name] = package.name
          end
        end

        package_to_package = {}
        package_to_external_consts.each do |package_name, const_names|
          uniq_set = Set.new
          const_names.map do |const_name|
            uniq_set.add(const_to_package_name.fetch(const_name, "UnknownPackage"))
          end
          package_to_package[package_name] = uniq_set.to_a
        end
        package_to_package
      end

      def extract_external_const(packages)
        packages.each_with_object({}) do |package, acc|
          acc[package.name] = package.external_references
        end
      end

      def find_out_const_location(meta_per_file)
        const_to_location_candidates = {}

        meta_per_file.each do |file, analyzed_result|
          analyzed_result.collected_constants.each do |const|
            const_to_location_candidates[const] ||= Set.new
            const_to_location_candidates[const] << file
          end
        end

        const_to_location = {}
        const_to_location_candidates.each do |const_name, candidates|
          path = ConstantLocationGuessor.call(const_name, candidates)
          const_to_location[const_name] = path if path
        end
        const_to_location
      end

      def process_asts(files)
        files.each_with_object({}) do |file, result_per_file|
          source_code = File.read(file)
          result_per_file[file] = Analyzer.analyze(file, source_code)
        end
      end

      def aggregation_filepaths_from_package(packages)
        packages.each_with_object(Set.new) do |package, all_files|
          raise "Some files of #{package.name} are scanned more then once." if all_files.intersect?(package.files)

          all_files.merge(package.files)
        end
      end

      # Expected config file scheme
      # - name: SomePackage
      #   recursive_include: true
      #   include_paths:
      #     - lib/a.rb
      #
      # @return [Array<CrimeScene::Package>]
      def load_packages(packages_config)
        packages_config.map do |package_config|
          PackageConfig.new(package_config).build_package.tap(&:load_file_path!)
        end
      end

      def append_reference_to_package(packages, meta_per_file)
        packages.each do |package|
          package.files.each do |file|
            next unless meta_per_file[file]

            refs = meta_per_file[file].collected_references.flat_map { |_k, v| v }
            package.add_references(refs)
          end
        end
      end

      def append_const_location_to_package(packages, const_to_location)
        location_to_consts = {}
        const_to_location.each do |const_name, location|
          location_to_consts[location] ||= Set.new
          location_to_consts[location] << const_name
        end

        packages.each do |package|
          package.files.each do |file|
            next unless location_to_consts[file]

            package.add_constants(location_to_consts[file])
          end
        end
      end
    end
  end
end
