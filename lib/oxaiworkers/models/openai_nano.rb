# frozen_string_literal: true

module OxAiWorkers
  module Models
    class OpenaiNano < OpenaiMax
      def initialize(uri_base: nil, api_key: nil, model: nil, max_tokens: nil, temperature: nil, frequency_penalty: nil)
        @model = model || 'gpt-4.1-nano'
        super(uri_base:, api_key:, model: @model, max_tokens:, temperature:, frequency_penalty:)
      end
    end
  end
end
