# frozen_string_literal: true

require "parser/current"

module CrimeScene
  module Analyzer # rubocop:disable Style/Documentation
    class UnsupportedFormatError < StandardError; end

    Result = Struct.new(:collected_constants, :collected_references, keyword_init: true)

    module_function

    def analyze_ruby(_path, source_code)
      ast = make_ast(source_code)

      processor = AstProcessor.new
      processor.process(ast) unless ast.nil?
      res = processor.result

      Result.new(
        collected_constants: res[:collected_constants],
        collected_references: res[:collected_references]
      )
    end

    # XXXXXXXXXXX
    def analyze_view(path, source_code)
      # XXX: Super hook!!
      identifier = path.split("/views/").last

      result = Result.new(
        collected_constants: [],
        collected_references: {}
      )
      source_code.scan(/\b(([A-Z][A-Za-z0-9_-]*::)*[A-Z][A-Za-z0-9_-]*)\b/) do |matched|
        result.collected_references[identifier] ||= []
        result.collected_references[identifier] << matched.first
      end

      result
    end

    def analyze(path, source_code)
      case File.extname(path)
      when ".rb"
        analyze_ruby(path, source_code)
      when ".haml", ".erb"
        analyze_view(path, source_code)
      else
        raise UnsupportedFormatError, "Unsupported format #{File.extname(path)}(#{path})!"
      end
    end

    def make_ast(source_code)
      Parser::CurrentRuby.parse(source_code)
    end
  end
end
