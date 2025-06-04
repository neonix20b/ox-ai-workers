# frozen_string_literal: true

module OxAiWorkers
  class ModuleRequest
    attr_accessor :result, :client, :messages, :model, :custom_id, :tools, :errors,
                  :tool_calls, :is_truncated,
                  :call_stack, :last_call, :stop_double_calls

    def initialize_requests(model:, call_stack: nil)
      @custom_id = SecureRandom.uuid
      @model = model
      @client = nil
      @is_truncated = false
      @call_stack = call_stack
      @last_call = nil

      if @model.api_key.nil?
        error_text = "#{@model.model} access token missing!"
        raise OxAiWorkers::ConfigurationError, error_text
      end

      cleanup
    end

    def cleanup
      @client ||= @model.client
      @result = nil
      @errors = nil
      @messages = []
      @tool_calls = nil
      @is_truncated = false
      # @last_call = nil
    end

    def append(role: nil, content: nil, messages: nil)
      @messages << { role:, content: } if role.present? && content.present?
      @messages += messages if messages.present?
    end

    def params
      @messages.each do |message|
        content = message[:content]
        if content.is_a?(String)
          OxAiWorkers.logger.warn "Request (String)[#{message[:role]}]: #{content.truncate(500)}"
        elsif content.is_a?(Array)
          types = content.map do |item|
            "#{item[:type]}: #{item[:content]&.truncate(500)}"
          end.compact.join(', ')
          OxAiWorkers.logger.warn "Request (Array): [#{types}]"
        else
          OxAiWorkers.logger.warn "Request (Other): #{message.inspect}"
        end
      end

      filtered_functions = []
      filtered_functions << @last_call if @stop_double_calls.include?(@last_call)

      tool_choice = if @call_stack&.any?
                      func1 = @call_stack.first
                      @call_stack = @call_stack.drop(1)
                      func1
                    end

      @model.build_parameters(
        messages: @messages,
        tools: @tools,
        filtered_functions:,
        tool_choice:
      )
    end

    def not_found_is_ok
      yield
    rescue Faraday::ResourceNotFound => e
      nil
    end

    def parse_choices(response)
      # Reset instance variables before processing choices
      @result = nil
      @tool_calls = []
      @is_truncated = false

      @model.parse_response(response) do |result, is_truncated, tool_calls|
        @result = result
        @is_truncated = is_truncated
        @tool_calls += tool_calls
      end
      @last_call = @tool_calls.last[:name] if @tool_calls.any?
    end
  end
end
