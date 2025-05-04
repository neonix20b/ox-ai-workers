# frozen_string_literal: true

require 'ptools'

module OxAiWorkers
  module Tool
    #
    # A tool that wraps the Ruby file system classes.
    #
    # Usage:
    #    file_system = OxAiWorkers::Tool::FileSystem.new
    #
    class FileSystem
      include OxAiWorkers::ToolDefinition
      include OxAiWorkers::DependencyHelper
      include OxAiWorkers::LoadI18n

      attr_accessor :current_dir

      def initialize(current_dir: nil, only: nil)
        depends_on 'ptools'

        store_locale

        init_white_list_with only

        define_function :list_directory,
                        description: I18n.t('oxaiworkers.tool.file_system.list_directory.description') do
          property :directory_path, type: 'string',
                                    description: I18n.t('oxaiworkers.tool.file_system.list_directory.directory_path'),
                                    required: true
        end

        define_function :read_file, description: I18n.t('oxaiworkers.tool.file_system.read_file.description') do
          property :file_path, type: 'string', description: I18n.t('oxaiworkers.tool.file_system.read_file.file_path'),
                               required: true
        end

        define_function :write_to_file, description: I18n.t('oxaiworkers.tool.file_system.write_to_file.description') do
          property :file_path, type: 'string',
                               description: I18n.t('oxaiworkers.tool.file_system.write_to_file.file_path'), required: true
          property :content, type: 'string', description: I18n.t('oxaiworkers.tool.file_system.write_to_file.content'),
                             required: true
        end

        @current_dir = current_dir
      end

      def list_directory(directory_path:)
        path = full_path(directory_path)
        OxAiWorkers.logger.info("Listing directory: #{path}", for: self.class)
        list = Dir.entries(path)
        list.delete_if { |f| f.start_with?('.') }
        if list.present?
          "Contents of directory \"#{path}\":\n #{list.join("\n")}"
        else
          "Directory is empty: #{path}"
        end
      rescue Errno::ENOENT
        "No such directory: #{path}"
      end

      def read_file(file_path:)
        path = full_path(file_path)
        OxAiWorkers.logger.info("Reading file: #{path}", for: self.class)
        if File.binary?(path)
          "File is binary: #{path}"
        else
          File.read(path).to_s
        end
      rescue Errno::ENOENT
        "No such file: #{path}"
      end

      def write_to_file(file_path:, content:)
        path = full_path(file_path)
        OxAiWorkers.logger.info("Writing to file: #{path}", for: self.class)
        # Ensure directory exists if using current_dir
        FileUtils.mkdir_p(File.dirname(path)) if @current_dir.present? && !Dir.exist?(File.dirname(path))
        File.write(path, content)
        "Content was successfully written to the file: #{path}"
      rescue Errno::EACCES
        "Permission denied: #{path}"
      end

      private

      def full_path(path)
        @current_dir.present? ? File.join(@current_dir, path) : path
      end
    end
  end
end
