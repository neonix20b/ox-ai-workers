module OxAiWorkers
  module Tool
    class Pipeline
      include OxAiWorkers::ToolDefinition
      include OxAiWorkers::DependencyHelper
      include OxAiWorkers::LoadI18n

      attr_accessor :worker

      def initialize(worker:, only: nil)
        store_locale

        init_white_list_with only

        define_function :generate_image, description: I18n.t('oxaiworkers.tool.pixels.generate_image.description') do
          property :prompt, type: 'string', description: I18n.t('oxaiworkers.tool.pixels.generate_image.prompt'),
                            required: true
          property :size, type: 'string', description: I18n.t('oxaiworkers.tool.pixels.generate_image.size'),
                          enum: %w[1024x1792 1792x1024 1024x1024]
          property :quality, type: 'string', description: I18n.t('oxaiworkers.tool.pixels.generate_image.quality'),
                             enum: %w[standard hd]
        end

        @worker = worker
      end

      def generate_image(prompt:, size: '1024x1792', quality: 'standard')
        response = @worker.client.images.generate(
          parameters: {
            prompt:,
            model: 'dall-e-3',
            size:,
            quality:
          }
        )

        url = response.dig('data', 0, 'url')
        puts url
        puts response.inspect
        response
      end
    end
  end
end
