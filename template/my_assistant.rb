# frozen_string_literal: true

require 'colorize'
require_relative 'tools/my_tool'

class MyAssistant
  include OxAiWorkers::Assistant::ModuleBase

  def initialize(delayed: false, model: nil)
    # Optional instructions
    # steps = []
    # steps << 'Step 1. Develop your own solution to the problem, taking initiative and making assumptions.'
    # steps << "Step 2. Enclose all your developments from the previous step in the #{OxAiWorkers::Iterator.full_function_name(:inner_monologue)} function."
    # steps << 'Step 3. Call the necessary functions one after another until the desired result is achieved.'
    # steps << "Step 4. When all intermediate steps are completed and the exact content of previous messages is no longer relevant, use the #{OxAiWorkers::Iterator.full_function_name(:summarize)} function."
    # steps << "Step 5. When the solution is ready, notify about it and wait for the user's response."

    # To retain the locale if you have assistants in different languages in your project.
    # store_locale # Optional

    @iterator = OxAiWorkers::Iterator.new(
      worker: init_worker(delayed: delayed, model: model),
      role: 'You are a software agent inside my computer',
      tools: [MyTool.new],
      # locale: @locale || I18n.locale,
      # steps: steps,
      # def_except: [:summarize], # It's except steps with that functions
      # def_only: [:inner_monologue, :outer_voice], # Use it only with your steps
      on_inner_monologue: ->(text:) { puts "monologue: #{text}".colorize(:yellow) },
      on_outer_voice: ->(text:) { puts "voice: #{text}".colorize(:green) },
      on_action_request: ->(text:) { puts "action: #{text}".colorize(:red) },
      on_summarize: ->(text:) { puts "summary: #{text}".colorize(:blue) }
    )
  end
end
