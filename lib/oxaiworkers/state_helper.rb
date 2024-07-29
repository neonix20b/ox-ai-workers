module OxAiWorkers::StateHelper
  def log_me(transition)
    # puts "`#{transition.event}` was called to transition from :#{transition.from} to :#{transition.to}"
  end
end