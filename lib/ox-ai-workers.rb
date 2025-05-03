# frozen_string_literal: true

require 'faraday'
require 'faraday/multipart'
require 'colorize'
require 'openai'
require 'yaml'
require 'json'

require_relative 'oxaiworkers/version'
require_relative 'oxaiworkers/contextual_logger'
require_relative 'oxaiworkers/load_i18n'
require_relative 'oxaiworkers/present_compat'
require_relative 'oxaiworkers/tool_definition'
require_relative 'oxaiworkers/dependency_helper'

require_relative 'oxaiworkers/module_request'
require_relative 'oxaiworkers/state_helper'
require_relative 'oxaiworkers/state_batch'
require_relative 'oxaiworkers/state_tools'
require_relative 'oxaiworkers/delayed_request'
require_relative 'oxaiworkers/iterator'
require_relative 'oxaiworkers/image_iterator'
require_relative 'oxaiworkers/request'

require_relative 'oxaiworkers/tool/eval'
require_relative 'oxaiworkers/tool/database'
require_relative 'oxaiworkers/tool/file_system'
require_relative 'oxaiworkers/tool/pipeline'

require_relative 'oxaiworkers/assistant/module_base'
require_relative 'oxaiworkers/assistant/sysop'
require_relative 'oxaiworkers/assistant/coder'
require_relative 'oxaiworkers/assistant/localizer'
require_relative 'oxaiworkers/assistant/orchestrator'
require_relative 'oxaiworkers/assistant/painter'
require_relative 'oxaiworkers/models/module_base'
require_relative 'oxaiworkers/models/openai_max'
require_relative 'oxaiworkers/models/openai_mini'
require_relative 'oxaiworkers/models/openai_nano'
require_relative 'oxaiworkers/models/deepseek_max'

require_relative 'oxaiworkers/engine' if defined?(Rails)

module OxAiWorkers
  DEFAULT_MAX_TOKEN = 4096
  DEFAULT_TEMPERATURE = 0.7

  class Error < StandardError; end
  class ConfigurationError < Error; end

  class Configuration
    attr_accessor :max_tokens, :temperature, :wait_for_complete, :access_token_deepseek, :access_token_openai

    def initialize
      @max_tokens = DEFAULT_MAX_TOKEN
      @temperature = DEFAULT_TEMPERATURE
      @wait_for_complete = true

      @access_token_deepseek = nil
      @access_token_openai = nil

      [Array, NilClass, String, Symbol, Hash].each do |c|
        c.send(:include, OxAiWorkers::PresentCompat) unless c.method_defined?(:present?)
      end
      String.include OxAiWorkers::CamelizeCompat unless String.method_defined?(:camelize)
    end
  end

  class << self
    attr_writer :configuration
    attr_reader :logger
    attr_accessor :default_model

    # @param logger [Logger]
    # @return [ContextualLogger]
    def logger=(logger)
      @logger = ContextualLogger.new(logger)
    end
  end

  self.logger ||= ::Logger.new($stdout, level: :info)

  def self.configuration
    @configuration ||= OxAiWorkers::Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end
