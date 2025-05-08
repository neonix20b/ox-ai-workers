module OxAiWorkers
  module Models
    class OpenaiDalle3 < ImagesBase
      def initialize(api_key: nil, _timeout: 60, options: {})
        @sizes = %w[1024x1024 1024x1792 1792x1024]
        @qualities = %w[standard hd]
        api_key ||= OxAiWorkers::Config.access_token_openai

        @client = OpenAI::Client.new(api_key:)
        super(options:)
      end

      def generate_image(prompt:, size: nil, quality: nil)
        size ||= @sizes.first
        quality ||= @qualities.first

        options = {
          prompt:,
          model: 'dall-e-3',
          size:,
          quality:
        }
        options.merge!(@options)

        response = @client.images.generate(
          parameters: options
        )

        url = response.dig('data', 0, 'url')
        b64_json = response.dig('data', 0, 'b64_json')
        revised_prompt = response.dig('data', 0, 'revised_prompt')

        @result = "revised_prompt: #{revised_prompt}\n\n"
        if url.present?
          @result += "url: #{url}\n\n"
          URI.open(url).read
        elsif b64_json.present?
          Base64.decode64(b64_json)
        else
          nil
        end
      end
    end
  end
end
