# frozen_string_literal: true

class MyTool
  extend OxAiWorkers::ToolDefinition # (!) extend

  define_function :sh, description: 'Execute a sh command and get the result (stdout + stderr)' do
    property :input, type: 'string', description: 'Source command', required: true
  end

  # Alternative implementation if you need to filter functions during initialization.
  # include OxAiWorkers::ToolDefinition # (!) include
  # include OxAiWorkers::LoadI18n # to support multiple languages
  #
  # def initialize(only: nil)
  #   store_locale # To retain the locale if you have MyTool in different languages.
  #   init_white_list_with only
  #   define_function :sh, description:  I18n.t('Execute a sh command and get the result (stdout + stderr)') do
  #     property :input, type: 'string', description:  I18n.t('Source command'), required: true
  #   end
  # end

  def sh(input:)
    OxAiWorkers.logger.info("Executing sh: \"#{input}\"", for: self.class)
    stdout_and_stderr_s, = Open3.capture2e(input)
    stdout_and_stderr_s
  end
end
