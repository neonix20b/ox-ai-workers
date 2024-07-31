# frozen_string_literal: true

require 'colorize'
require_relative 'tools/my_tool'

class MyAssistant
  include OxAiWorkers::Assistant::ModuleBase

  def initialize(delayed: false, model: nil)
    @iterator = OxAiWorkers::Iterator.new(
      worker: init_worker(delayed: delayed, model: model),
      role: 'You are a software agent inside my computer',
      tools: [MyTool.new],
      on_inner_monologue: ->(text:) { puts "monologue: #{text}".colorize(:yellow) },
      on_outer_voice: ->(text:) { puts "voice: #{text}".colorize(:green) },
      on_action_request: ->(text:) { puts "action: #{text}".colorize(:red) },
      on_pack_history: ->(text:) { puts "summary: #{text}".colorize(:blue) }
    )
  end
end
