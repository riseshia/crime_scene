# frozen_string_literal: true

module CrimeScene
  module StorageAdaptor
    FileNotFound = StandardError.new

    # Main storage
    class File
      def find(find_path, &block)
        Find.find(find_path) do |path|
          block.call(path)
        end
      end

      def read(path)
        raise FileNotFound, "'#{path}' is not exist" unless File.exist?(path)

        ::File.read(path)
      end
    end

    # Memory storage. e.g. used for test
    class Memory
      def initialize
        @data = {}
      end

      def find(find_path)
        @data.each_key do |path|
          yield if path.include?(find_path)
        end
      end

      def read(path)
        raise FileNotFound, "'#{path}' is not exist" unless @data.key?(path)

        @data.fetch(path)
      end

      # @param data [Hash<String, String>] path => body
      def load(data)
        @data = data.dup
      end
    end
  end
end
