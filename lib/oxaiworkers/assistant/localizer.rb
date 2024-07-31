# frozen_string_literal: true

module OxAiWorkers
  module Assistant
    class Localizer
      include OxAiWorkers::Assistant::ModuleBase

      def initialize(delayed: false, model: nil, language: 'русский', locale: :ru, source: 'english')
        @iterator = Iterator.new(
          worker: init_worker(delayed: delayed, model: model),
          role: format(I18n.t('oxaiworkers.assistant.localizer.role'), language),
          tools: [Tool::Eval.new, Tool::FileSystem.new],
          on_inner_monologue: ->(text:) { puts Rainbow("monologue: #{text}").yellow },
          on_outer_voice: ->(text:) { puts Rainbow("voice: #{text}").green },
          on_action_request: ->(text:) { puts Rainbow("action: #{text}").red },
          on_pack_history: ->(text:) { puts Rainbow("summary: #{text}").blue }
        )
        @iterator.add_context(format(I18n.t('oxaiworkers.assistant.localizer.source'), source))

        @iterator.add_context(format(I18n.t('oxaiworkers.assistant.localizer.locale'),
                                     language, locale))
      end
    end
  end
end
