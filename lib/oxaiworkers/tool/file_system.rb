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
      extend OxAiWorkers::ToolDefinition
      include OxAiWorkers::DependencyHelper

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

      def initialize
        depends_on 'ptools'
      end

      def list_directory(directory_path:)
        OxAiWorkers.logger.info("Listing directory: #{directory_path}", for: self.class)
        list = Dir.entries(directory_path)
        list.delete_if { |f| f.start_with?('.') }
        if list.present?
          "Contents of directory \"#{directory_path}\":\n #{list.join("\n")}"
        else
          "Directory is empty: #{directory_path}"
        end
      rescue Errno::ENOENT
        "No such directory: #{directory_path}"
      end

      def read_file(file_path:)
        OxAiWorkers.logger.info("Reading file: #{file_path}", for: self.class)
        if File.binary?(file_path)
          "File is binary: #{file_path}"
        else
          File.read(file_path).to_s
        end
      rescue Errno::ENOENT
        "No such file: #{file_path}"
      end

      def write_to_file(file_path:, content:)
        OxAiWorkers.logger.info("Writing to file: #{file_path}", for: self.class)
        File.write(file_path, content)
        "Content was successfully written to the file: #{file_path}"
      rescue Errno::EACCES
        "Permission denied: #{file_path}"
      end
    end
  end
end
