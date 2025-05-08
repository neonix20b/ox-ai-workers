module OxAiWorkers
  module Models
    class StabilityImages < ImagesBase
      def initialize(api_key: nil, timeout: 60, options: {})
        @sizes = %w[auto]
        @qualities = %w[auto]
        api_key ||= OxAiWorkers::Config.access_token_stability

        @client = StabilitySDK::Client.new(api_key:, timeout:)
        super(options:)
      end

      def generate(prompt:, _size: nil, _quality: nil)
        options = {
          engine_id: 'stable-diffusion-xl-1024-v1-0'
        }
        options.merge!(@options)
        binary = nil
        @client.generate(prompt, options) do |answer|
          answer.artifacts.each do |artifact|
            next unless artifact.type == :ARTIFACT_IMAGE

            binary = artifact.binary
          end
        end

        binary
      end
    end
  end
end
