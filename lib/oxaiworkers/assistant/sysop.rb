# frozen_string_literal: true

module OxAiWorkers
  module Assistant
    class Sysop
      include OxAiWorkers::Assistant::ModuleBase

      def initialize(delayed: false, model: nil)
        @iterator = OxAiWorkers::Iterator.new(
          worker: initWorker(delayed: delayed, model: model),
          role: I18n.t('oxaiworkers.assistant.sysop.role'),
          tools: [OxAiWorkers::Tool::Eval.new],
          on_inner_monologue: ->(text:) { puts Rainbow("monologue: #{text}").yellow },
          on_outer_voice: ->(text:) { puts Rainbow("voice: #{text}").green },
          on_action_request: ->(text:) { puts Rainbow("action: #{text}").red },
          on_pack_history: ->(text:) { puts Rainbow("summary: #{text}").blue }
        )
      end
    end
  end
end
