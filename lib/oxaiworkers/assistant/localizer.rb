# frozen_string_literal: true

module OxAiWorkers
  module Assistant
    class Localizer
      include OxAiWorkers::Assistant::ModuleBase

      attr_accessor :source_lang, :target_lang

      def initialize(title: nil,
                     description: nil,
                     capabilities: nil,
                     source_lang: 'en',
                     target_lang: nil,
                     delayed: false,
                     model: nil,
                     on_stream: nil)
        @source_lang = source_lang
        @target_lang = target_lang
        store_locale
        with_locale do
          title ||= I18n.t('oxaiworkers.assistant.localizer.title')
          description ||= I18n.t('oxaiworkers.assistant.localizer.description')
          capabilities ||= I18n.t('oxaiworkers.assistant.localizer.capabilities').split(', ')
        end
        super(title:,
              description:,
              capabilities:,
              delayed:,
              model:,
              on_stream:)
      end

      def initialize_iterator(delayed:, model:, on_stream:)
        store_locale
        @iterator = Iterator.new(
          worker: init_worker(delayed:, model:, on_stream:),
          role: format_role,
          tools: [Tool::FileSystem.new],
          locale: @locale,
          on_inner_monologue: default_on_inner_monologue,
          on_outer_voice: default_on_outer_voice,
          on_action_request: default_on_action_request,
          on_summarize: default_on_summarize
        )

        add_localizer_context
      end

      def format_role
        with_locale do
          if @target_lang.present?
            I18n.t('oxaiworkers.assistant.localizer.role_with_target',
                   source_lang: @source_lang, target_lang: @target_lang)
          else
            I18n.t('oxaiworkers.assistant.localizer.role', source_lang: @source_lang)
          end
        end
      end

      def add_localizer_context
        with_locale do
          @iterator.add_context(I18n.t('oxaiworkers.assistant.localizer.source', @source_lang))
          if @target_lang.present?
            @iterator.add_context(
              I18n.t('oxaiworkers.assistant.localizer.locale', @target_lang, @target_lang.to_sym)
            )
          end
        end
      end
    end
  end
end
