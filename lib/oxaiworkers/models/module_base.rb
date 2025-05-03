# frozen_string_literal: true

module OxAiWorkers
  module Models
    module ModuleBase
      attr_accessor :uri_base, :api_key, :model, :max_tokens, :temperature

      def initialize(uri_base:, api_key:, model:, max_tokens: nil, temperature: nil)
        @max_tokens = max_tokens || OxAiWorkers.configuration.max_tokens
        @temperature = temperature || OxAiWorkers.configuration.temperature
        @api_key = api_key
        @uri_base = uri_base
        @model = model
      end
    end
  end
end
