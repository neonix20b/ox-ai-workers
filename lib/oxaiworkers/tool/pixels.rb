require 'fileutils'
require 'open-uri'

module OxAiWorkers
  module Tool
    class Pixels
      include OxAiWorkers::ToolDefinition
      include OxAiWorkers::DependencyHelper
      include OxAiWorkers::LoadI18n

      attr_accessor :worker, :url, :tmp_dir

      def initialize(worker:, tmp_dir:, only: nil)
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
        @tmp_dir = tmp_dir
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
          save_generated_image(file_name:)
          "url: #{@url}\nfile_name: #{file_name}\n\nrevised_prompt: #{revised_prompt}"
        else
          "url: #{@url}\n\nrevised_prompt: #{revised_prompt}"
        end
      end

      def save_generated_image(file_name:)
        return 'Image not generated. Please generate image first.' unless @url

        # Ensure tmp_dir exists
        FileUtils.mkdir_p(@tmp_dir) unless Dir.exist?(@tmp_dir)

        path = File.join(@tmp_dir, file_name)

        File.open(path, 'wb') do |file|
          file.write(URI.open(@url).read)
        end

        path
      end
    end
  end
end
