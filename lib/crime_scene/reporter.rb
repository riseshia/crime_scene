# frozen_string_literal: true

require "json"
require "yaml"

module CrimeScene
  # convert data with specified format
  # Supported format: :yml, :json, :dot
  module Reporter
    class << self
      def format(packages, format: :yml)
        case format
        when :yml
          data = packages.map(&:export)
          YAML.dump(data)
        when :json
          data = packages.map(&:export)
          JSON.dump(data)
        when :dot
          format_dot(packages)
        else
          raise "Unsupported output format #{format}"
        end
      end

      private def format_dot(packages)
        lines = packages.map do |pkg|
          nodes = pkg.depend_package_names.map { |n| %("#{n}") }.join(" ")
          %(  "#{pkg.name}" -> { #{nodes} };)
        end

        <<~DOT
          digraph dependency_gragh {
          #{lines.join("\n")
          }
        DOT
      end
    end
  end
end
