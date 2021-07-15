# frozen_string_literal: true

require "haml"

require "parser/current"

module CrimeScene
  module CallInViewTracer
    module Analyzer # rubocop:disable Style/Documentation
      class UnsupportedFormatError < StandardError; end

      Result = Struct.new(:path, :called_methods, keyword_init: true)

      module_function

      def analyze_ruby(path, source_code)
        ast = make_ast(source_code)

        processor = AstProcessor.new
        processor.process(ast) unless ast.nil?
        res = processor.result

        Result.new(
          path: path,
          called_methods: res[:called_methods]
        )
      rescue Parser::SyntaxError
        raise "Parse error with #{path}"
      end

      def analyze_haml(path, source_code)
        # XXX: Super hook!!
        identifier = path.split("/views/").last

        source_code = Haml::Engine.new(source_code).precompiled
        result = analyze_ruby(identifier, source_code)
        called_methods = result[:called_methods].fetch("", [])
        called_methods_from_haml = %w[_hamlout]

        Result.new(
          path: path,
          called_methods: { path => called_methods - called_methods_from_haml }
        )
      end

      ERB_DELIMETER = /(=?<%[#=-]?)(.+?)(=?-?%>)/m.freeze
      def extract_ruby_code(source_code)
        ruby_lines = []
        tmp = ""
        source_code.each_line do |line|
          tmp += line
          res = tmp.scan(ERB_DELIMETER)

          next if res.empty? # keep string in tmp

          res.each do |matched|
            next if matched.first == "<%#" # comment

            # last '-' trimming
            ruby_code = matched[1].end_with?("-") ? matched[1][..-2] : matched[1]
            ruby_lines << ruby_code
          end
          tmp = "" # reset
        end

        ruby_lines.join("\n")
      end

      # XXX: Rails patch erb syntax, we can't make valid ast without that...
      def analyze_erb(path, source_code)
        # XXX: Super hook!!
        identifier = path.split("/views/").last

        result = analyze_ruby(identifier, extract_ruby_code(source_code))

        Result.new(
          path: path,
          called_methods: { path => result[:called_methods].fetch("", []) }
        )
      end

      def analyze(path, source_code)
        case File.extname(path)
        when ".rb"
          analyze_ruby(path, source_code)
        when ".haml"
          analyze_haml(path, source_code)
        when ".erb"
          analyze_erb(path, source_code)
        else
          raise UnsupportedFormatError, "Unsupported format #{File.extname(path)}(#{path})!"
        end
      end

      def make_ast(source_code)
        Parser::CurrentRuby.parse(source_code)
      end
    end
  end
end
