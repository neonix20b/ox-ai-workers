# frozen_string_literal: true

require 'open3'

module OxAiWorkers
  module Tool
    class Eval
      include OxAiWorkers::ToolDefinition
      include OxAiWorkers::DependencyHelper
      include OxAiWorkers::LoadI18n

      attr_accessor :current_dir

      def initialize(only: nil, current_dir: nil)
        store_locale

        init_white_list_with only
        @current_dir = current_dir

        define_function :ruby, description: I18n.t('oxaiworkers.tool.eval.ruby.description') do
          property :input, type: 'string', description: I18n.t('oxaiworkers.tool.eval.ruby.input'), required: true
        end

        define_function :sh, description: I18n.t('oxaiworkers.tool.eval.sh.description') do
          property :input, type: 'string', description: I18n.t('oxaiworkers.tool.eval.sh.input'), required: true
        end
      end

      def ruby(input:)
        OxAiWorkers.logger.info("Executing ruby: \"#{input}\"", for: self.class)
        execute_in_directory { eval(input) }
      end

      def sh(input:)
        OxAiWorkers.logger.info("Executing sh: \"#{input}\"", for: self.class)
        execute_in_directory do
          stdout_and_stderr_s, status = Open3.capture2e(input)
          stdout_and_stderr_s.present? ? stdout_and_stderr_s : status.to_s
        end
      end

      private

      def execute_in_directory(&block)
        if @current_dir.present?
          Dir.chdir(@current_dir, &block)
        else
          yield
        end
      rescue StandardError => e
        OxAiWorkers.logger.debug(e.message, for: self.class)
        e.message
      end
    end
  end
end
