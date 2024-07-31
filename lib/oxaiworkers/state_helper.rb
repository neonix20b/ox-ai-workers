# frozen_string_literal: true

module OxAiWorkers
  module StateHelper
    def log_me(transition)
      # OxAiWorkers.logger.debug("`#{transition.event}` was called to transition from :#{transition.from} to :#{transition.to}")
    end
  end
end
