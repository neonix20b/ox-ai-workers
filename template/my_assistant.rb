# frozen_string_literal: true

require_relative 'tools/my_tool'

class MyAssistant
  include OxAiWorkers::Assistant::ModuleBase

  def initialize(delayed: false, model: nil)
    @iterator = OxAiWorkers::Iterator.new(
      worker: initWorker(delayed: delayed, model: model),
      role: 'You are a helpful assistant',
      tools: [MyTool.new]
    )
  end
end
