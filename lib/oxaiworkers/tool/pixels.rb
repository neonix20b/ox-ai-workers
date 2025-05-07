require 'fileutils'
require 'open-uri'

module OxAiWorkers
  module Tool
    class Pixels
      include OxAiWorkers::ToolDefinition
      include OxAiWorkers::DependencyHelper
      include OxAiWorkers::LoadI18n

      attr_accessor :worker, :url, :current_dir, :image_model, :mask

      MODELS = {
        'dall-e-3' => {
          'model' => 'dall-e-3',
          'size' => %w[1024x1024 1024x1792 1792x1024],
          'quality' => %w[standard hd]
        },
        'gpt-image-1' => {
          'model' => 'gpt-image-1',
          'size' => %w[1024x1024 1024x1792 1792x1024],
          'quality' => %w[auto low medium high]
        }
      }

      def initialize(worker:, current_dir: nil, only: nil, image_model: 'dall-e-3', mask: nil)
        store_locale

        init_white_list_with only

        define_function :generate_image, description: I18n.t('oxaiworkers.tool.pixels.generate_image.description') do
          property :prompt, type: 'string', description: I18n.t('oxaiworkers.tool.pixels.generate_image.prompt'),
                            required: true
          property :size, type: 'string', description: I18n.t('oxaiworkers.tool.pixels.generate_image.size'),
                          enum: MODELS[image_model]['size']
          if current_dir.present?
            property :file_name, type: 'string',
                                 description: I18n.t('oxaiworkers.tool.pixels.generate_image.file_name'),
                                 required: true
          end
          property :quality, type: 'string', description: I18n.t('oxaiworkers.tool.pixels.generate_image.quality'),
                             enum: MODELS[image_model]['quality']
        end

        # define_function :edit_image, description: I18n.t('oxaiworkers.tool.pixels.edit_image.description') do
        #   property :input_image, type: 'string', description: I18n.t('oxaiworkers.tool.pixels.edit_image.input_image'),
        #                          required: true
        #   property :prompt, type: 'string', description: I18n.t('oxaiworkers.tool.pixels.edit_image.prompt'),
        #                     required: true
        #   if current_dir.present?
        #     property :output_file_name, type: 'string',
        #                                 description: I18n.t('oxaiworkers.tool.pixels.generate_image.file_name'),
        #                                 required: true
        #   end
        # end

        @worker = worker
        @current_dir = current_dir
        @image_model = MODELS[image_model]
        @mask = mask
      end

      def generate_image(prompt:, file_name: nil, size: nil, quality: nil)
        puts "generate_image: #{prompt}"

        size ||= @image_model['size'].first
        quality ||= @image_model['quality'].first

        response = @worker.client.images.generate(
          parameters: {
            prompt:,
            model: @image_model['model'],
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

      def edit_image(input_image:, prompt:, output_file_name: nil, size: nil, mask: nil)
        size ||= @image_model['size'].first
        mask ||= @mask

        response = @worker.client.images.edit(
          parameters: {
            image: input_image,
            model: @image_model['model'],
            prompt:,
            size:,
            mask:
          }
        )

        @url = response.dig('data', 0, 'url')
        revised_prompt = response.dig('data', 0, 'revised_prompt')
        if output_file_name.present?
          path = save_generated_image(file_name: output_file_name)
          "url: #{@url}\nfile_name: #{path}\n\nrevised_prompt: #{revised_prompt}"
        else
          "url: #{@url}\n\nrevised_prompt: #{revised_prompt}"
        end
      end

      def save_generated_image(file_name:)
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
