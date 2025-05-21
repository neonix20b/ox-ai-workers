# frozen_string_literal: true

module OxAiWorkers
  module Models
    class LLMBase
      attr_accessor :uri_base, :api_key, :model, :max_tokens, :temperature, :frequency_penalty

      def initialize(uri_base:, api_key:, model:, max_tokens: nil, temperature: nil, frequency_penalty: nil)
        @max_tokens = max_tokens || OxAiWorkers.configuration.max_tokens
        @temperature = temperature || OxAiWorkers.configuration.temperature
        @frequency_penalty = frequency_penalty || 0
        @api_key = api_key
        @uri_base = uri_base
        @model = model
      end

      def request(parameters)
        client.chat(parameters:)
      end

      def client
        @client ||= OpenAI::Client.new(
          access_token: @api_key,
          uri_base: @uri_base,
          log_errors: true # Highly recommended in development, so you can see what errors OpenAI is returning. Not recommended in production because it could leak private data to your logs.
        )
      end

      def build_parameters(messages:, tools: [], filtered_functions: [], tool_choice: nil)
        parameters = {
          model: @model,
          messages:,
          temperature: @temperature,
          max_completion_tokens: @max_tokens,
          frequency_penalty: @frequency_penalty
        }
        if tools.present?
          functions = tools.map(&:to_openai_format).flatten

          parameters[:tools] = functions.reject { |f| filtered_functions.include?(f[:name]) }

          parameters[:tool_choice] =
            tool_choice.nil? ? 'required' : { type: 'function', function: { name: tool_choice } }
        end
        parameters
      end

      def tool_call(name:, args:, call_id:, out:)
        [
          {
            role: :assistant,
            tool_calls: [{
              id: "call_#{call_id}",
              type: 'function',
              function: {
                name:,
                arguments: args.to_json
              }
            }]
          },
          {
            role: :tool,
            content: out.present? ? out : "Tool call #{name} successful.",
            tool_call_id: "call_#{call_id}"
          }
        ]
      end

      def add_base64(binary:, filename:, text:, mime_type:, detail: 'auto')
        content = []
        content << { type: 'text', text: } if text.present?
        content << if mime_type.include?('image')
                     { type: 'image_url',
                       image_url: { 
                                    url: "data:#{mime_type};base64,#{Base64.strict_encode64(binary)}",
                                    detail: 
                                  } 
                      }
                   else
                     {
                       type: 'file',
                       file: {
                         filename:,
                         file_data: "data:#{mime_type};base64,#{Base64.strict_encode64(binary)}"
                       }
                     }
                   end
        content
      end

      def add_url(url:, text:, detail: 'auto')
        content = []
        content << { type: 'text', text: } if text.present?
        content << { type: 'image_url', image_url: { url:, detail: } }
        content
      end

      def parse_response(response, &)
        choices = response['choices']
        return if choices.nil? || choices.empty?

        choices.each do |choice|
          arr = parse_one_choice(choice)
          yield(arr)
        end
      end

      def parse_one_choice(choice)
        message = choice['message']
        return unless message # Skip if there's no message in this choice

        # Accumulate raw tool calls if present
        tool_calls_raw = message['tool_calls']

        # Update result with the content if present
        current_result = message['content']
        @result = current_result if current_result.present?

        # Update finish reason and truncation status based on the *last* choice's reason
        current_finish_reason = choice['finish_reason']
        @is_truncated = (current_finish_reason == 'length')

        @tool_calls = _parse_tool_calls(tool_calls_raw) unless @is_truncated || tool_calls_raw.empty?
        [@result, @is_truncated, @tool_calls]
      end

      def _parse_tool_calls(tool_calls_raw)
        tool_calls = [] # Ensure it's clean before parsing
        tool_calls_raw.each do |tool_call|
          next unless tool_call['type'] == 'function' # Ensure it's a function call

          function = tool_call['function']
          next unless function && function['name'] && function['arguments']

          begin
            # Attempt to parse arguments, handle potential JSON errors
            args = JSON.parse(function['arguments'], symbolize_names: true)
          rescue JSON::ParserError => e
            OxAiWorkers.logger.error("Failed to parse tool call arguments: #{e.message}", for: self.class)
            OxAiWorkers.logger.debug("Raw arguments: #{function['arguments']}", for: self.class)
            # Decide how to handle parsing errors, e.g., skip this call or add with empty args
            # Skipping for now, as partial args are likely useless.
            next
          end
          OxAiWorkers.logger.debug("function: #{function.inspect}", for: self.class)
          # Accumulate parsed tool calls
          next if function['name'].empty?

          tool_calls << {
            class: function['name'].split('__').first,
            name: function['name'].split('__').last,
            args:
          }
          # @last_call = function['name'].to_s
        end
        tool_calls
      end
    end
  end
end
