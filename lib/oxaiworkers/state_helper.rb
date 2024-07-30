# frozen_string_literal: true

module OxAiWorkers
  module StateHelper
    def log_me(transition)
      # puts "`#{transition.event}` was called to transition from :#{transition.from} to :#{transition.to}"
    end
  end
end
