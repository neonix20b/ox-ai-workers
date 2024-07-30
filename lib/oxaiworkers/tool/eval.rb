# frozen_string_literal: true

require 'open3'

module OxAiWorkers
  module Tool
    class Eval
      extend OxAiWorkers::ToolDefinition
      include OxAiWorkers::DependencyHelper

      # define_function :ruby, description: I18n.t('oxaiworkers.tool.eval.ruby.description') do
      #   property :input, type: 'string', description: I18n.t('oxaiworkers.tool.eval.ruby.input'), required: true
      # end

      define_function :sh, description: I18n.t('oxaiworkers.tool.eval.sh.description') do
        property :input, type: 'string', description: I18n.t('oxaiworkers.tool.eval.sh.input'), required: true
      end

      # def ruby(input:)
      #   puts Rainbow("Executing ruby: \"#{input}\"").red
      #   eval(input)
      # end

      def sh(input:)
        puts Rainbow("Executing sh: \"#{input}\"").red
        begin
          stdout_and_stderr_s, status = Open3.capture2e(input)
          return stdout_and_stderr_s if stdout_and_stderr_s.present?

          status.to_s
        rescue StandardError => e
          e.message
        end
      end
    end
  end
end
