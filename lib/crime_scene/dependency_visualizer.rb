# frozen_string_literal: true

require "yaml"

module CrimeScene
  # Entrypoint of Dependency calculation.
  module DependencyVisualizer # rubocop:disable Metrics/ModuleLength
    DependencyVisualizerConfig = Struct.new(:target_paths, :known_constants, keyword_init: true)
    class << self
      # @return [Hash<String, Array<String>>] { package_name => [package_name] }
      def call(packages_config_path) # rubocop:disable Metrics/AbcSize
        yaml = YAML.safe_load(
          File.read(packages_config_path),
          permitted_classes: [Symbol],
          symbolize_names: true
        )
        path_to_config_file = File.dirname(packages_config_path)

        dv_config = DependencyVisualizerConfig.new(
          target_paths: yaml[:config][:target_paths],
          known_constants: yaml[:config][:known_constants].transform_keys(&:to_s)
        )
        packages_config = yaml[:packages]

        packages = nil
        meta_per_file = nil
        Dir.chdir(path_to_config_file) do
          target_files = FilepathScanner.call(
            dv_config.target_paths,
            recursive_scan: true
          )
          packages = load_packages(packages_config)
          all_files_in_package = aggregation_filepaths_from_package(packages)
          if target_files != all_files_in_package
            warn "Some files are not in package:"
            (target_files - all_files_in_package).each do |file|
              warn "- #{file}"
            end
            exit 1
          end

          meta_per_file = process_asts(all_files_in_package)
        end

        const_to_location = find_out_const_location(meta_per_file, dv_config)
        append_const_location_to_package(packages, const_to_location)
        append_reference_to_package(packages, meta_per_file)

        append_depend_package_names_to_package(packages)

        packages
      end

      def append_depend_package_names_to_package(packages)
        package_to_external_consts = extract_external_const(packages)

        package_to_package = convert_const_to_package(packages, package_to_external_consts)

        packages.each do |package|
          package.depend_package_names = package_to_package[package.name]
        end
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
            uniq_set.add(const_to_package_name.fetch(const_name, "UnknownExternalPackage"))
          end
          package_to_package[package_name] = uniq_set.to_a.sort
        end
        package_to_package
      end

      def extract_external_const(packages)
        packages.each_with_object({}) do |package, acc|
          acc[package.name] = package.external_references
        end
      end

      def find_out_const_location(meta_per_file, dv_config)
        const_to_location_candidates = {}

        meta_per_file.each do |file, analyzed_result|
          analyzed_result.collected_constants.each do |const|
            const_to_location_candidates[const] ||= Set.new
            const_to_location_candidates[const] << file
          end
        end

        const_to_location = {}
        const_to_location_candidates.each do |const_name, candidates|
          path = ConstantLocationGuessor.call(const_name, candidates, dv_config.known_constants)
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
          handle_intersect(all_files & package.files, packages) if all_files.intersect?(package.files)

          all_files.merge(package.files)
        end
      end

      def handle_intersect(conflicted_files, packages) # rubocop:disable Metrics/AbcSize
        conflict_packages = {}
        conflicted_files.each do |file|
          conflict_packages[file] = []

          packages.each do |package|
            conflict_packages[file] << package if package.files.member?(file)
          end
        end

        warn "Some files are scanned more than one package."
        conflict_packages.each do |file, cpkgs|
          warn "Conflicted file: #{file}"
          warn "which founded from:"
          cpkgs.each do |package|
            warn "- #{package.name}:"
            warn "  -#{package.include_paths.to_a}"
          end
        end
        exit 1
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

      def append_reference_to_package(packages, meta_per_file) # rubocop:disable Metrics/AbcSize
        all_collected = meta_per_file.flat_map { |_k, v| v.collected_constants.to_a }
        all_consts = ReferenceConstantResolver.generate_missing_modules(all_collected)

        packages.each do |package|
          package.files.each do |file|
            next unless meta_per_file[file]

            refs = Set.new
            meta_per_file[file].collected_references.each do |scope_name, const_names|
              const_names.each do |const_name|
                qualified = ReferenceConstantResolver.call(scope_name, const_name, all_consts)
                refs.add(qualified)
              end
            end

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
