module OxAiWorkers
  module Models
    class OpenaiGptImage < ImagesBase
      def initialize(api_key: nil, _timeout: 60, options: {})
        @sizes = %w[auto 1024x1024 1536x1024 1024x1536]
        @qualities = %w[auto low medium high]
        api_key ||= OxAiWorkers::Config.access_token_openai

        @client = OpenAI::Client.new(api_key:)
        super(options:)
      end

      def generate_image(prompt:, size: nil, quality: nil)
        size ||= @sizes.first
        quality ||= @qualities.first

        options = {
          prompt:,
          model: 'gpt-image-1',
          size:,
          quality:
        }
        options.merge!(@options)

        response = @client.images.generate(
          parameters: options
        )

        b64_json = response.dig('data', 0, 'b64_json')

        Base64.decode64(b64_json)
      end
    end
  end
end
