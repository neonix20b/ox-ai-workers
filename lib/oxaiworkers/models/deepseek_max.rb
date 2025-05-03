# frozen_string_literal: true

module OxAiWorkers
  module Models
    class DeepseekMax
      include OxAiWorkers::Models::ModuleBase

      def initialize(uri_base: nil, api_key: nil, model: nil, max_tokens: nil, temperature: nil)
        @model = model || 'deepseek-chat'
        @uri_base = uri_base || 'https://api.deepseek.com/'
        @api_key = api_key || OxAiWorkers.configuration.access_token_deepseek
        super(uri_base: @uri_base, api_key: @api_key, model: @model, max_tokens:, temperature:)
      end
    end
  end
end
