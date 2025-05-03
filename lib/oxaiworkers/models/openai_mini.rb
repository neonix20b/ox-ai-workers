# frozen_string_literal: true

module OxAiWorkers
  module Models
    class OpenaiMini < OpenaiMax
      def initialize(uri_base: nil, api_key: nil, model: nil, max_tokens: nil, temperature: nil)
        @model = model || 'gpt-4.1-mini'
        super(uri_base:, api_key:, model: @model, max_tokens:, temperature:)
      end
    end
  end
end
