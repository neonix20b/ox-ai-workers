# frozen_string_literal: true

module OxAiWorkers
  class ModuleRequest
    attr_accessor :result, :client, :messages, :model, :custom_id, :tools, :errors,
                  :tool_calls_raw, :tool_calls, :is_truncated, :finish_reason, :on_stream_proc

    def initialize_requests(model:, on_stream: nil)
      @custom_id = SecureRandom.uuid
      @model = model
      @client = nil
      @is_truncated = false
      @finish_reason = nil
      @on_stream_proc = on_stream

      if @model.api_key.nil?
        error_text = "#{@model.model} access token missing!"
        raise OxAiWorkers::ConfigurationError, error_text
      end

      cleanup
    end

    def cleanup
      @client ||= OpenAI::Client.new(
        access_token: @model.api_key,
        uri_base: @model.uri_base,
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
        model: @model.model,
        messages: @messages,
        temperature: @model.temperature,
        max_tokens: @model.max_tokens
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
        # Parse basic info and accumulate raw tool calls
        parse_one_choice(choice)
      end

      # Only parse tool calls if the response wasn't truncated
      _parse_tool_calls unless @is_truncated || @tool_calls_raw.empty?
    end

    def parse_one_choice(choice)
      message = choice['message']
      return unless message # Skip if there's no message in this choice

      # Accumulate raw tool calls if present
      @tool_calls_raw.concat(message['tool_calls']) if message['tool_calls']

      # Update result with the content if present
      current_result = message['content']
      @result = current_result if current_result.present?

      # Update finish reason and truncation status based on the *last* choice's reason
      current_finish_reason = choice['finish_reason']
      if current_finish_reason.present?
        @finish_reason = current_finish_reason
        @is_truncated = (@finish_reason == 'length')
      end
    end

    private

    # Parses the accumulated raw tool calls into the structured @tool_calls array.
    # This should only be called after confirming the response is not truncated.
    def _parse_tool_calls
      @tool_calls = [] # Ensure it's clean before parsing
      @tool_calls_raw.each do |tool_call|
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

        # Accumulate parsed tool calls
        @tool_calls << {
          class: function['name'].split('__').first,
          name: function['name'].split('__').last,
          args: args
        }
      end
    end
  end
end
