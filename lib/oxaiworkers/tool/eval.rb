# frozen_string_literal: true

require 'open3'

module OxAiWorkers
  module Tool
    class Eval
      include OxAiWorkers::ToolDefinition
      include OxAiWorkers::DependencyHelper
      include OxAiWorkers::LoadI18n

      def initialize(only: nil)
        store_locale

        init_white_list_with only

        define_function :ruby, description: I18n.t('oxaiworkers.tool.eval.ruby.description') do
          property :input, type: 'string', description: I18n.t('oxaiworkers.tool.eval.ruby.input'), required: true
        end

        define_function :sh, description: I18n.t('oxaiworkers.tool.eval.sh.description') do
          property :input, type: 'string', description: I18n.t('oxaiworkers.tool.eval.sh.input'), required: true
        end
      end

      def ruby(input:)
        puts "Executing ruby: \"#{input}\"".colorize(:red)
        eval(input)
      end

      def sh(input:)
        OxAiWorkers.logger.info("Executing sh: \"#{input}\"", for: self.class)
        begin
          stdout_and_stderr_s, status = Open3.capture2e(input)
          return stdout_and_stderr_s if stdout_and_stderr_s.present?

          status.to_s
        rescue StandardError => e
          OxAiWorkers.logger.debug(e.message, for: self.class)
          e.message
        end
      end
    end
  end
end
