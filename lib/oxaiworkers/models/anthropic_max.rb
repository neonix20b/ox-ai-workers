# frozen_string_literal: true

module OxAiWorkers
  module Models
    class AnthropicMax < LLMBase
      def initialize(uri_base: nil, api_key: nil, model: nil, max_tokens: nil, temperature: nil, frequency_penalty: nil)
        @model = model || 'claude-3-7-sonnet-latest'
        @uri_base = uri_base # || 'https://api.anthropic.com/v1/'
        @api_key = api_key || OxAiWorkers.configuration.access_token_anthropic
        super(uri_base: @uri_base, api_key: @api_key, model: @model, max_tokens:, temperature:, frequency_penalty:)
      end

      def client
        @client ||= Anthropic::Client.new(
          access_token: @api_key,
          uri_base: @uri_base,
          log_errors: true
        )
      end

      def request(parameters)
        client.messages(parameters:)
      end

      def build_parameters(messages:, tools: [], filtered_functions: [], tool_choice: nil)
        parameters = {
          model: @model,
          system: messages.select { |m| m[:role] == :system }.map { |m| m[:content] }.join("\n\n"),
          messages: messages.reject { |m| m[:role] == :system },
          temperature: @temperature,
          max_tokens: @max_tokens
        }
        if tools.present?
          functions = tools.map(&:to_anthropic_format).flatten

          @names = functions.map { |f| f[:name] }

          parameters[:tools] = functions.reject { |f| filtered_functions.include?(f[:name]) }

          parameters[:tool_choice] =
            tool_choice.nil? ? { type: 'any' } : { type: 'tool', name: tool_choice }
        end
        parameters
      end

      def tool_call(name:, args:, call_id:, out:)
        [
          {
            role: :assistant,
            content: [
              {
                type: 'tool_use',
                id: "call_#{call_id}",
                name:,
                input: args
              }
            ]
          },
          {
            role: :user,
            content: [
              {
                type: 'tool_result',
                tool_use_id: "call_#{call_id}",
                content: out.present? ? out : "Tool call #{name} successful."
              }
            ]
          }
        ]
      end

      def add_base64(binary:, text:, mime_type:)
        content = []
        content << { type: 'text', text: } if text.present?
        content << {
                      type: mime_type.include?('image') ? 'image' : 'document',
                      source: {
                        type: 'base64',
                        media_type: mime_type,
                        data: Base64.strict_encode64(binary)
                      }
                    }
        content
      end

      def add_url(url:, text:, mime_type:)
        content = []
        content << { type: 'text', text: } if text.present?
        content << {
                      type: mime_type.include?('image') ? 'image' : 'document',
                      source: {
                        type: 'url',
                        url: url
                      }
                    }
        content
      end

      def parse_response(response, &)
        choices = response['content']
        @is_truncated = (response['stop_reason'] == 'max_tokens')
        return if choices.nil? || choices.empty?

        choices.each do |choice|
          result, tool_calls = parse_one_choice(choice)
          yield(result, @is_truncated, tool_calls)
        end
      end

      def parse_one_choice(choice)
        return unless choice # Skip if there's no choice

        # Initialize result variables
        @result = nil
        @tool_calls = []

        # Process content item
        if choice['type'] == 'tool_use'
          # Handle tool use
          begin
            # Attempt to parse arguments, handle potential JSON errors
            args = JSON.parse(choice['input'].to_json, symbolize_names: true)
          rescue JSON::ParserError => e
            OxAiWorkers.logger.error("Failed to parse tool call arguments: #{e.message}", for: self.class)
            OxAiWorkers.logger.debug("Raw arguments: #{choice['input']}", for: self.class)
          end

          fname = @names.find { |n| n.end_with?(choice['name']) }
          if fname != choice['name']
            OxAiWorkers.logger.error("Tool call name #{choice['name']} not found. Using #{fname} instead.",
                                     for: self.class)
          end

          tool_call = {
            class: fname.split('__').first,
            name: fname.split('__').last,
            args:
          }
          @tool_calls << tool_call
        elsif choice['type'] == 'text'
          # Handle text content
          @result = choice['text']
        end

        [@result, @tool_calls]
      end
    end
  end
end
