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
      @tool_calls = []
      @result = response.dig('choices', 0, 'message', 'content')
      @tool_calls_raw = response.dig('choices', 0, 'message', 'tool_calls')
      @finish_reason = response.dig('choices', 0, 'finish_reason')
      @is_truncated = @finish_reason == 'length'

      return @tool_calls if @tool_calls_raw.nil?

      @tool_calls_raw.each do |tool|
        function = tool['function']
        args = JSON.parse(YAML.load(function['arguments']).to_json, { symbolize_names: true })
        @tool_calls << {
          class: function['name'].split('__').first,
          name: function['name'].split('__').last,
          args:
        }
      end

      @tool_calls
    end
  end
end
