# frozen_string_literal: true

module OxAiWorkers
  class ModuleRequest
    attr_accessor :result, :client, :messages, :model, :max_tokens, :custom_id, :temperature, :tools, :errors,
                  :tool_calls_raw, :tool_calls, :is_truncated, :finish_reason, :uri_base, :on_stream_proc

    def initialize_requests(model: nil, max_tokens: nil, temperature: nil, uri_base: nil, on_stream: nil)
      @max_tokens = max_tokens || OxAiWorkers.configuration.max_tokens
      @custom_id = SecureRandom.uuid
      @model = model || OxAiWorkers.configuration.model
      @temperature = temperature || OxAiWorkers.configuration.temperature
      @uri_base = uri_base
      @client = nil
      @is_truncated = false
      @finish_reason = nil
      @on_stream_proc = on_stream

      OxAiWorkers.configuration.access_token ||= ENV['OPENAI']
      if OxAiWorkers.configuration.access_token.nil?
        error_text = 'OpenAi access token missing!'
        raise OxAiWorkers::ConfigurationError, error_text
      end

      cleanup
    end

    def cleanup
      @client ||= OpenAI::Client.new(
        access_token: OxAiWorkers.configuration.access_token,
        uri_base: @uri_base || OxAiWorkers.configuration.uri_base,
        log_errors: true # Highly recommended in development, so you can see what errors OpenAI is returning. Not recommended in production because it could leak private data to your logs.
      )
      @result = nil
      @errors = nil
      @messages = []
      @tool_calls = nil
      @tool_calls_raw = nil
      @is_truncated = false
      @finish_reason = nil
    end

    def append(role: nil, content: nil, messages: nil)
      @messages << { role:, content: } if role.present? && content.present?
      @messages += messages if messages.present?
    end

    def params
      parameters = {
        model: @model,
        messages: @messages,
        temperature: @temperature,
        max_tokens: @max_tokens
      }
      if @tools.present?
        parameters[:tools] = @tools
        parameters[:tool_choice] = 'required'
      end
      if @on_stream_proc.present?
        parameters[:stream] = @on_stream_proc
        parameters[:stream_options] = { include_usage: true }
      end
      parameters
    end

    def not_found_is_ok
      yield
    rescue Faraday::ResourceNotFound => e
      nil
    end

    def parse_choices(response)
      # Reset instance variables before processing choices
      @result = nil
      @tool_calls_raw = []
      @tool_calls = []
      @finish_reason = nil
      @is_truncated = false

      choices = response['choices']
      return if choices.nil? || choices.empty?

      choices.each do |choice|
        parse_one_choice(choice)
      end

      # @tool_calls is already populated by parse_one_choice
      # @result, @finish_reason, @is_truncated are updated with the last relevant values
    end

    def parse_one_choice(choice)
      message = choice['message']
      return unless message # Skip if there's no message in this choice

      # Accumulate raw tool calls
      if message['tool_calls']
        @tool_calls_raw.concat(message['tool_calls'])
        message['tool_calls'].each do |tool_call|
          next unless tool_call['type'] == 'function' # Ensure it's a function call

          function = tool_call['function']
          next unless function && function['name'] && function['arguments']

          begin
            # Attempt to parse arguments, handle potential JSON errors
            args = JSON.parse(function['arguments'], symbolize_names: true)
          rescue JSON::ParserError => e
            OxAiWorkers.logger.error("Failed to parse tool call arguments: #{e.message}", for: self.class)
            OxAiWorkers.logger.debug("Raw arguments: #{function['arguments']}", for: self.class)
            args = {} # Assign empty args or handle error as appropriate
          end

          # Accumulate parsed tool calls
          @tool_calls << {
            class: function['name'].split('__').first,
            name: function['name'].split('__').last,
            args: args
          }
        end
      end

      # Update result with the content if present
      current_result = message['content']
      @result = current_result if current_result.present?

      # Update finish reason and truncation status
      current_finish_reason = choice['finish_reason']
      if current_finish_reason.present?
        @finish_reason = current_finish_reason
        @is_truncated = @finish_reason == 'length'
      end
    end
  end
end
