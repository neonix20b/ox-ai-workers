# frozen_string_literal: true

module OxAiWorkers
  module Models
    class AnthropicMax < LLMBase
      def initialize(uri_base: nil, api_key: nil, model: nil, max_tokens: nil, temperature: nil, frequency_penalty: nil)
        @model = model || 'claude-3-7-sonnet-latest'
        @uri_base = uri_base || 'https://api.anthropic.com/v1/'
        @api_key = api_key || OxAiWorkers.configuration.access_token_anthropic
        super(uri_base:, api_key: @api_key, model: @model, max_tokens:, temperature:, frequency_penalty:)
      end
    end
  end
end
