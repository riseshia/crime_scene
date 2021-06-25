# frozen_string_literal: true

require "parser/current"

require_relative "ast_processor"

module CrimeScene
  module Analyzer # rubocop:disable Style/Documentation
    class UnsupportedFormatError < StandardError; end

    Result = Struct.new(:collected_constants, :collected_references, keyword_init: true)

    module_function

    def analyze_ruby(source_code)
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
    def analyze_view(_source_code)
      result = Result.new(
        collected_constants: [],
        collected_references: []
      )
      scan(/\b(([A-Z][A-Za-z0-9_-]*::)*[A-Z][A-Za-z0-9_-]*)\b/) do |matched|
        result.collected_references << matched.first
      end

      result
    end

    def analyze_file(path)
      source_code = File.read(path)

      case File.extname(path)
      when ".rb"
        analyze_ruby(source_code)
      when ".haml", ".erb"
        analyze_view(source_code)
      else
        raise UnsupportedFormatError, "Unsupported format #{File.extname(path)}(#{path})!"
      end
    end

    def make_ast(source_code)
      Parser::CurrentRuby.parse(source_code)
    end
  end
end
