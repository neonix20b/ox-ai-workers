# frozen_string_literal: true

module OxAiWorkers
  class Request < OxAiWorkers::ModuleRequest
    alias initialize initialize_requests

    def finish
      @custom_id = SecureRandom.uuid
      cleanup
    end

    def request!
      response = @client.chat(parameters: params)
      parse_choices(response)
    rescue OpenAI::Error => e
      OxAiWorkers.logger.debug(e.inspect, for: self.class)
    end

    def requested?
      false
    end

    def completed?
      @result.present? or @errors.present? or @tool_calls.present?
    end
  end
end
