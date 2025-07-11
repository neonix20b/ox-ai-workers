# frozen_string_literal: true

module OxAiWorkers
  class Request < OxAiWorkers::ModuleRequest
    alias initialize initialize_requests

    def finish
      @custom_id = SecureRandom.uuid
      cleanup
    end

    # Method to finish without clearing messages
    def finish_without_cleanup
      @custom_id = SecureRandom.uuid
      # Clear only result and errors, but not messages
      @result = nil
      @errors = nil
      @tool_calls = nil
      @is_truncated = false
    end

    def request!
      response = @model.request(params)
      parse_choices(response)
    end

    def requested?
      false
    end

    def completed?
      # Truncated response is not considered complete,
      # so the iterator continues processing
      return false if @is_truncated

      @result.present? or @errors.present? or @tool_calls.present?
    end
  end
end
