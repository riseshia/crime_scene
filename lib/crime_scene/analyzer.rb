# frozen_string_literal: true

require "haml"

require "parser/current"

module CrimeScene
  module Analyzer # rubocop:disable Style/Documentation
    class UnsupportedFormatError < StandardError; end

    Result = Struct.new(:collected_constants, :collected_references, keyword_init: true)

    module_function

    def analyze_ruby(path, source_code)
      ast = make_ast(source_code)

      processor = AstProcessor.new
      processor.process(ast) unless ast.nil?
      res = processor.result

      Result.new(
        collected_constants: res[:collected_constants],
        collected_references: res[:collected_references]
      )
    rescue Parser::SyntaxError
      raise "Parse error with #{path}"
    end

    def analyze_haml(path, source_code)
      # XXX: Super hook!!
      identifier = path.split("/views/").last

      source_code = Haml::Engine.new(source_code).precompiled
      result = analyze_ruby(identifier, source_code)

      used_by_haml_compiler = ["Hash", "Array", "Haml::Helpers"]

      # collected_references can't be empty, since Haml compiler
      actually_used = result.collected_references.values.first - used_by_haml_compiler
      Result.new(
        collected_constants: [],
        collected_references: { identifier => actually_used }
      )
    end

    # XXX: Rails patch erb syntax, we can't make valid ast without that...
    ERB_DELIMETER = /(=?<%[#=-]?)(.+)(=?-?%>)/.freeze
    def analyze_erb(path, source_code)
      # XXX: Super hook!!
      identifier = path.split("/views/").last

      ruby_lines = []
      source_code.scan(ERB_DELIMETER) do |matched|
        next if matched.first == "<%#" # comment

        ruby_lines << matched[1]
      end

      result = analyze_ruby(identifier, ruby_lines.join("\n"))

      collected_references =
        if result.collected_references.empty?
          {}
        else
          { identifier => result.collected_references.values.first }
        end

      Result.new(
        collected_constants: [],
        collected_references: collected_references
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
