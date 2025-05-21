require 'fileutils'
require 'open-uri'

module OxAiWorkers
  module Tool
    class Wolfram
      include OxAiWorkers::ToolDefinition
      include OxAiWorkers::DependencyHelper
      include OxAiWorkers::LoadI18n

      attr_accessor :access_token, :location

      def initialize(only: nil, access_token: nil, location: nil)
        store_locale

        init_white_list_with only

        define_function :ask, description: I18n.t('oxaiworkers.tool.wolfram_alpha.ask.description') do
          property :prompt, type: 'string', description: I18n.t('oxaiworkers.tool.wolfram_alpha.ask.prompt'),
                            required: true
          if location.nil?
            property :location, type: 'string', description: I18n.t('oxaiworkers.tool.wolfram_alpha.ask.location'),
                                required: false
          end
        end

        @access_token = access_token
        @location = location
      end

      def ask(prompt:, location: nil)
        location ||= @location
        options = { location: }
        api_key = @access_token || OxAiWorkers.configuration.access_token_wolfram
        @wolfram ||= WolframAlpha::Client.new api_key, options.compact
        response = @wolfram.query prompt
        input = response['Input'] # Get the input interpretation pod.
        result = ''
        result = "Input interpretation:\n#{input.subpods.map(&:plaintext).join("\n")}\n\n" unless input.nil?
        result += response.pods.map { |p| [p.title, p.subpods.map(&:plaintext).join("\n")].join(":\n") }.join("\n\n")
        images = []
        %w[Plots Result Image].each do |title|
          plot = response.find { |pod| pod.title == title }
          images += plot.subpods.map { |img| img&.image } unless plot.nil?
        end
        images = images.compact.filter { |i| i[:type] != 'Default' }.uniq
        result += "\n\n" + images.map { |img| "![#{img[:alt]}](\"#{img[:src]}\")" }.join("\n") unless images.empty?
        result
      end
    end
  end
end
