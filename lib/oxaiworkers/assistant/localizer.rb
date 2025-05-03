# frozen_string_literal: true

module OxAiWorkers
  module Assistant
    class Localizer
      include OxAiWorkers::Assistant::ModuleBase

      def initialize(delayed: false, model: nil, language: 'русский', locale: :ru, source: 'english')
        store_locale

        with_locale do
          @id = 'localizer'
          @role = format(I18n.t('oxaiworkers.assistant.localizer.role'), source_lang: source)
          @description = I18n.t('oxaiworkers.assistant.localizer.description')
          @capabilities = I18n.t('oxaiworkers.assistant.localizer.capabilities').split(',').map(&:strip)
          @title = I18n.t('oxaiworkers.assistant.localizer.title')
        end

        @iterator = Iterator.new(
          worker: init_worker(delayed:, model:),
          role: @role,
          tools: [Tool::Eval.new, Tool::FileSystem.new],
          locale: @locale,
          on_inner_monologue: ->(text:) { puts "monologue: #{text}".colorize(:yellow) },
          on_outer_voice: ->(text:) { puts "voice: #{text}".colorize(:green) }
        )
        @iterator.add_context(format(I18n.t('oxaiworkers.assistant.localizer.source'), source_lang: source))

        @iterator.add_context(format(I18n.t('oxaiworkers.assistant.localizer.locale'),
                                     target_lang: language, locale:))
      end
    end
  end
end
