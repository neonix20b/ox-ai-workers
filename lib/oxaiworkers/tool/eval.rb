# frozen_string_literal: true

module OxAiWorkers::Tool
  #
  # A calculator tool that falls back to the Google calculator widget
  #
  # Gem requirements:
  #     gem "eqn", "~> 1.6.5"
  #     gem "google_search_results", "~> 2.0.0"
  #
  # Usage:
  #     calculator = OxAiWorkers::Tool::Calculator.new
  #
  class Eval
    extend OxAiWorkers::ToolDefinition
    include OxAiWorkers::DependencyHelper

    define_function :ruby, description: I18n.t("oxaiworkers.tool.eval.ruby.description") do
      property :input, type: "string", description: I18n.t("oxaiworkers.tool.eval.ruby.input"), required: true
    end

    define_function :sh, description: I18n.t("oxaiworkers.tool.eval.sh.description") do
      property :input, type: "string", description: I18n.t("oxaiworkers.tool.eval.sh.input"), required: true
    end

    def ruby(input:)
      puts Rainbow("Executing ruby: \"#{input}\"").red
      eval(input)
    end

    def sh(input:)
      puts Rainbow("Executing sh: \"#{input}\"").red
      stdout_and_stderr_s, _ = Open3.capture2e(input)
      return stdout_and_stderr_s
    end
  end
end