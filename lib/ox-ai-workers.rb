# frozen_string_literal: true

require 'faraday'
require 'faraday/multipart'
require 'rainbow'
require 'openai'
require 'yaml'
require 'json'

require_relative 'oxaiworkers/version'
require_relative 'oxaiworkers/load_i18n'
require_relative 'oxaiworkers/present_compat'
require_relative 'oxaiworkers/module_request'
require_relative 'oxaiworkers/state_helper'
require_relative 'oxaiworkers/state_batch'
require_relative 'oxaiworkers/state_tools'
require_relative 'oxaiworkers/tool_definition'
require_relative 'oxaiworkers/delayed_request'
require_relative 'oxaiworkers/dependency_helper'
require_relative 'oxaiworkers/iterator'
require_relative 'oxaiworkers/request'
require_relative 'oxaiworkers/tool/eval'

require_relative 'oxaiworkers/assistant/module_base'
require_relative 'oxaiworkers/assistant/sysop'

module OxAiWorkers
  DEFAULT_MODEL = 'gpt-4o-mini'
  DEFAULT_MAX_TOKEN = 4096
  DEFAULT_TEMPERATURE = 0.7

  class Error < StandardError; end
  class ConfigurationError < Error; end

  class Configuration
    attr_accessor :model, :max_tokens, :temperature, :access_token

    def initialize
      @access_token = nil
      @model = DEFAULT_MODEL
      @max_tokens = DEFAULT_MAX_TOKEN
      @temperature = DEFAULT_TEMPERATURE

      [Array, NilClass, String, Symbol, Hash].each do |c|
        c.send(:include, OxAiWorkers::PresentCompat) unless c.method_defined?(:present?)
      end
      String.include OxAiWorkers::CamelizeCompat unless String.method_defined?(:camelize)
    end
  end

  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= OxAiWorkers::Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end
