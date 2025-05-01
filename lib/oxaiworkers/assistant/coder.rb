# frozen_string_literal: true

module OxAiWorkers
  module Assistant
    class Coder
      include OxAiWorkers::Assistant::ModuleBase

      def initialize(delayed: false, model: nil, language: 'ruby')
        store_locale
        @iterator = Iterator.new(
          worker: init_worker(delayed: delayed, model: model),
          role: format(I18n.t('oxaiworkers.assistant.coder.role'), language),
          tools: [Tool::Eval.new, Tool::FileSystem.new],
          locale: @locale,
          on_inner_monologue: ->(text:) { puts "monologue: #{text}".colorize(:yellow) },
          on_outer_voice: ->(text:) { puts "voice: #{text}".colorize(:green) },
          on_action_request: ->(text:) { puts "action: #{text}".colorize(:red) },
          on_summarize: ->(text:) { puts "summary: #{text}".colorize(:blue) }
        )
      end

      def language=(language)
        with_locale do
          @iterator.role = format(I18n.t('oxaiworkers.assistant.coder.role'), language)
        end
      end
    end
  end
end
