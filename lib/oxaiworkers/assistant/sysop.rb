# frozen_string_literal: true

module OxAiWorkers
  module Assistant
    class Sysop
      include OxAiWorkers::Assistant::ModuleBase

      def initialize(delayed: false, model: nil)
        store_locale
        @iterator = Iterator.new(
          worker: init_worker(delayed: delayed, model: model),
          role: I18n.t('oxaiworkers.assistant.sysop.role'),
          tools: [Tool::Eval.new(only: :sh)],
          locale: @locale,
          on_inner_monologue: ->(text:) { puts "monologue: #{text}".colorize(:yellow) },
          on_outer_voice: ->(text:) { puts "voice: #{text}".colorize(:green) },
          on_action_request: ->(text:) { puts "action: #{text}".colorize(:red) },
          on_summarize: ->(text:) { puts "summary: #{text}".colorize(:blue) }
        )
      end
    end
  end
end
