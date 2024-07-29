class OxAiWorkers::ModuleRequest
  attr_accessor :result, :client, :messages, :model, :max_tokens, :custom_id, :temperature, :tools, :errors
  attr_accessor :tool_calls_raw, :tool_calls
  DEFAULT_MODEL = "gpt-4o-mini"
  DEFAULT_MAX_TOKEN = 4096
  DEFAULT_TEMPERATURE = 0.7

  def initializeRequests(model: DEFAULT_MODEL, max_tokens: DEFAULT_MAX_TOKEN, temperature: DEFAULT_TEMPERATURE)
    puts "call: ModuleRequest::#{__method__}"
    @max_tokens = max_tokens
    @custom_id = SecureRandom.uuid
    @model = model
    @temperature = temperature
    @client = nil
    
    OxAiWorkers.configuration.access_token ||= ENV["OPENAI"]
    if OxAiWorkers.configuration.access_token.nil?
      error_text = "OpenAi access token missing!"
      raise OxAiWorkers::ConfigurationError, error_text
    end

    cleanup()
  end

  def cleanup
    puts "call: ModuleRequest::#{__method__}"
    @client ||= OpenAI::Client.new(
                    access_token: OxAiWorkers.configuration.access_token,
                    log_errors: true # Highly recommended in development, so you can see what errors OpenAI is returning. Not recommended in production because it could leak private data to your logs.
                  )
    @result = nil
    @errors = nil
    @messages = []
  end

  def append role: nil, content: nil, messages: nil
    @messages << {role: role, content: content} if role.present? and content.present?
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
      parameters[:tool_choice] = "required"
    end
    parameters
  end

  def not_found_is_ok &block
    begin
      yield
    rescue Faraday::ResourceNotFound => e
      nil
    end
  end

  def parseChoices(response)
    puts response.inspect
    @tool_calls = []
    @result = response.dig("choices", 0, "message", "content")
    @tool_calls_raw = response.dig("choices", 0, "message", "tool_calls")

    @tool_calls_raw.each do |tool|
      function = tool["function"]
      args = JSON.parse(YAML.load(function["arguments"]).to_json, { symbolize_names: true } )
      @tool_calls << {
        class: function["name"].split("__").first,
        name: function["name"].split("__").last,
        args: args
      }
    end

    @tool_calls

    # Assistant.send(function_name, **args)
  end
end