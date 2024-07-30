# frozen_string_literal: true

require 'rainbow'
require_relative 'tools/my_tool'

class MyAssistant
  include OxAiWorkers::Assistant::ModuleBase

  def initialize(delayed: false, model: nil)
    @iterator = OxAiWorkers::Iterator.new(
      worker: init_worker(delayed: delayed, model: model),
      role: 'You are a software agent inside my computer',
      tools: [MyTool.new],
      on_inner_monologue: ->(text:) { puts Rainbow("monologue: #{text}").yellow },
      on_outer_voice: ->(text:) { puts Rainbow("voice: #{text}").green },
      on_action_request: ->(text:) { puts Rainbow("action: #{text}").red },
      on_pack_history: ->(text:) { puts Rainbow("summary: #{text}").blue }
    )
  end
end
