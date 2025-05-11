require 'fileutils'
require 'open-uri'

module OxAiWorkers
  module Tool
    class Pixels
      include OxAiWorkers::ToolDefinition
      include OxAiWorkers::DependencyHelper
      include OxAiWorkers::LoadI18n

      attr_accessor :worker, :current_dir

      def initialize(worker:, current_dir: nil, only: nil)
        store_locale

        init_white_list_with only

        define_function :generate_image, description: I18n.t('oxaiworkers.tool.pixels.generate_image.description') do
          property :prompt, type: 'string', description: I18n.t('oxaiworkers.tool.pixels.generate_image.prompt'),
                            required: true
          if worker.sizes.length > 1
            property :size, type: 'string', description: I18n.t('oxaiworkers.tool.pixels.generate_image.size'),
                            enum: worker.sizes
          end
          if current_dir.present?
            property :file_name, type: 'string',
                                 description: I18n.t('oxaiworkers.tool.pixels.generate_image.file_name'),
                                 required: true
          end
          if worker.qualities.length > 1
            property :quality, type: 'string', description: I18n.t('oxaiworkers.tool.pixels.generate_image.quality'),
                               enum: worker.qualities
          end
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
      end

      def generate_image(prompt:, file_name: nil, size: nil, quality: nil)
        binary = @worker.generate(prompt:, size:, quality:)

        if file_name.present?
          path = save_generated_image(file_name:, binary:)
          "Successfully generated image. file_name: #{path}\n\n#{@worker.result}"
        elsif @worker.result.present?
          @worker.result
        else
          'file_name not set for OxAiWorkers::Tool::Pixels. Please set file name first.'
        end
      end

      # def edit_image(input_image:, prompt:, output_file_name: nil, size: nil, mask: nil)
      #   # TODO: Implement edit_image
      # end

      def save_generated_image(file_name:, binary:)
        unless @current_dir.present?
          return 'Current directory not set for OxAiWorkers::Tool::Pixels. Please set current directory first.'
        end

        return 'File name not set for OxAiWorkers::Tool::Pixels. Please set file name first.' unless file_name.present?

        # Ensure current_dir exists
        FileUtils.mkdir_p(@current_dir) unless Dir.exist?(@current_dir)

        path = File.join(@current_dir, file_name)

        File.open(path, 'wb') do |file|
          file.write(binary)
        end

        puts "Successfully saved image. file_name: #{path}"

        file_name
      end
    end
  end
end
