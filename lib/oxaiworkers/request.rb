# frozen_string_literal: true

module OxAiWorkers
  class Request < OxAiWorkers::ModuleRequest
    alias initialize initializeRequests

    def finish
      @custom_id = SecureRandom.uuid
      cleanup
    end

    def request!
      response = @client.chat(parameters: params)
      parseChoices(response)
      # @result = response.dig("choices", 0, "message", "content")
      # puts response.inspect
    rescue OpenAI::Error => e
      puts e.inspect
    end

    def completed?
      @result.present? or @errors.present? or @tool_calls.present?
    end
  end
end
