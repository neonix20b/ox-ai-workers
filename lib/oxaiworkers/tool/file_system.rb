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
        puts Rainbow("Listing directory: #{directory_path}").magenta
        Dir.entries(directory_path)
      rescue Errno::ENOENT
        "No such directory: #{directory_path}"
      end

      def read_file(file_path:)
        puts Rainbow("Reading file: #{file_path}").magenta
        if File.binary?(file)
          "File is binary: #{file_path}"
        else
          File.read(file_path).to_s
        end
      rescue Errno::ENOENT
        "No such file: #{file_path}"
      end

      def write_to_file(file_path:, content:)
        puts Rainbow("Writing to file: #{file_path}").magenta
        File.write(file_path, content)
        "Content was successfully written to the file: #{file_path}"
      rescue Errno::EACCES
        "Permission denied: #{file_path}"
      end
    end
  end
end
