require 'fileutils'
require 'open-uri'

module OxAiWorkers
  module Tool
    class Pixels
      include OxAiWorkers::ToolDefinition
      include OxAiWorkers::DependencyHelper
      include OxAiWorkers::LoadI18n

      attr_accessor :worker, :url, :current_dir

      def initialize(worker:, current_dir: nil, only: nil)
        store_locale

        init_white_list_with only

        define_function :generate_image, description: I18n.t('oxaiworkers.tool.pixels.generate_image.description') do
          property :prompt, type: 'string', description: I18n.t('oxaiworkers.tool.pixels.generate_image.prompt'),
                            required: true
          property :size, type: 'string', description: I18n.t('oxaiworkers.tool.pixels.generate_image.size'),
                          enum: %w[1024x1792 1792x1024 1024x1024]
          property :file_name, type: 'string', description: I18n.t('oxaiworkers.tool.pixels.generate_image.file_name')
          property :quality, type: 'string', description: I18n.t('oxaiworkers.tool.pixels.generate_image.quality'),
                             enum: %w[standard hd]
        end

        @worker = worker
        @current_dir = current_dir
      end

      def generate_image(prompt:, file_name: nil, size: '1024x1792', quality: 'standard')
        puts "generate_image: #{prompt}"

        response = @worker.client.images.generate(
          parameters: {
            prompt:,
            model: 'dall-e-3',
            size:,
            quality:
          }
        )

        @url = response.dig('data', 0, 'url')
        revised_prompt = response.dig('data', 0, 'revised_prompt')
        if file_name.present?
          path = save_generated_image(file_name:)
          "url: #{@url}\nfile_name: #{path}\n\nrevised_prompt: #{revised_prompt}"
        else
          "url: #{@url}\n\nrevised_prompt: #{revised_prompt}"
        end
      end

      def save_generated_image(file_name:)
        return 'Image not generated. Please generate image first.' unless @url
        unless @current_dir.present?
          return 'Current directory not set for OxAiWorkers::Tool::Pixels. Please set current directory first.'
        end

        # Ensure current_dir exists
        FileUtils.mkdir_p(@current_dir) unless Dir.exist?(@current_dir)

        path = File.join(@current_dir, file_name)

        File.open(path, 'wb') do |file|
          file.write(URI.open(@url).read)
        end

        file_name
      end
    end
  end
end
