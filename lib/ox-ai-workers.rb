# frozen_string_literal: true

require "faraday"
require "faraday/multipart"
require "rainbow"
require "openai"
require "yaml"
require "json"

require_relative "oxaiworkers/version"
require_relative "oxaiworkers/present_compat.rb"
require_relative "oxaiworkers/module_request.rb"
require_relative "oxaiworkers/state_helper.rb"
require_relative "oxaiworkers/state_batch.rb"
require_relative "oxaiworkers/state_tools.rb"
require_relative "oxaiworkers/tool_definition.rb"
require_relative "oxaiworkers/delayed_request.rb"
require_relative "oxaiworkers/dependency_helper.rb"
require_relative "oxaiworkers/iterator.rb"
require_relative "oxaiworkers/request.rb"
require_relative "oxaiworkers/tool/eval.rb"
require_relative "oxaiworkers/version.rb"
require_relative "oxaiworkers/assistant/sysop.rb"

module OxAiWorkers
  DEFAULT_MODEL = "gpt-4o-mini"
  DEFAULT_MAX_TOKEN = 4096
  DEFAULT_TEMPERATURE = 0.7

  class Error < StandardError; end
  class ConfigurationError < Error; end

  class Configuration
    attr_writer :access_token
    attr_accessor :model, :max_tokens, :temperature

    def initialize
      @access_token = nil
      @model = DEFAULT_MODEL
      @max_tokens = DEFAULT_MAX_TOKEN
      @temperature = DEFAULT_TEMPERATURE

      [Array, NilClass, String, Symbol, Hash].each{|c| 
        c.send(:include, OxAiWorkers::PresentCompat) unless c.method_defined?(:present?)
      }
      String.send(:include, OxAiWorkers::CamelizeCompat) unless String.method_defined?(:camelize)
      
    end

    def access_token
      return @access_token
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
