# frozen_string_literal: true

module OxAiWorkers
  module Models
    class OpenaiWhisper
      def initialize(uri_base: nil, api_key: nil, model: 'whisper-1')
        @api_key = api_key || OxAiWorkers.configuration.access_token_openai
        @uri_base = uri_base
        @client = OpenAI::Client.new(access_token: @api_key, uri_base:)
        @model = model
      end

      def transcribe(binary:, language: nil)
        response = @client.audio.transcribe(
          parameters: {
            model: @model,
            file: binary,
            language:
          }
        )
        response['text']
      end
    end
  end
end
