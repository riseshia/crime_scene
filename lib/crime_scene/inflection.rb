# frozen_string_literal: true

require "parser/current"

module CrimeScene
  # Inflection Utilities
  module Inflection
    class << self
      def constantize(str)
        camelize(singularize(str))
      end

      def singularize(str)
        return str unless str.end_with?("s")

        if /.+(oes|sses|ses|shes|xes|zes|yes)$/.match?(str)
          str[0..-3]
        else
          str[0..-2]
        end
      end

      def camelize(string)
        string = string.sub(/^[a-z\d]*/, &:capitalize)
        string.gsub!(%r{(?:_|(/))([a-z\d]*)}i) do
          "#{Regexp.last_match(1)}#{Regexp.last_match(2).capitalize}"
        end
        string.gsub("/", "::")
      end
    end
  end
end
