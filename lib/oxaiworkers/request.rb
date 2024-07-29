class OxAiWorkers::Request < OxAiWorkers::ModuleRequest
  alias_method :initialize, :initializeRequests 

  def finish
    @custom_id = SecureRandom.uuid
    cleanup()
  end

  def request!
    begin
      response = @client.chat(parameters: params)
      parseChoices(response)
      #@result = response.dig("choices", 0, "message", "content")
      #puts response.inspect
    rescue OpenAI::Error => e
      puts e.inspect
    end
  end

  def completed?
    @result.present? or @errors.present? or @tool_calls.present?
  end
end
