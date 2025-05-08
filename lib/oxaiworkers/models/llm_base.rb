# frozen_string_literal: true

module OxAiWorkers
  module Models
    class LLMBase
      attr_accessor :uri_base, :api_key, :model, :max_tokens, :temperature, :frequency_penalty

      def initialize(uri_base:, api_key:, model:, max_tokens: nil, temperature: nil, frequency_penalty: nil)
        @max_tokens = max_tokens || OxAiWorkers.configuration.max_tokens
        @temperature = temperature || OxAiWorkers.configuration.temperature
        @frequency_penalty = frequency_penalty || 0
        @api_key = api_key
        @uri_base = uri_base
        @model = model
      end
    end
  end
end
