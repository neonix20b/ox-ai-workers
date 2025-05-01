# frozen_string_literal: true

module OxAiWorkers
  module Assistant
    class Coder
      include OxAiWorkers::Assistant::ModuleBase

      attr_accessor :language, :custom_role

      def initialize(title: nil,
                     description: nil,
                     capabilities: nil,
                     language: nil,
                     role: nil,
                     delayed: false,
                     model: nil,
                     on_stream: nil)
        @language = language
        @custom_role = role
        store_locale
        with_locale do
          title ||= I18n.t('oxaiworkers.assistant.coder.title')
          description ||= I18n.t('oxaiworkers.assistant.coder.description')
          capabilities ||= I18n.t('oxaiworkers.assistant.coder.capabilities').split(', ')
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
          tools: [Tool::Eval.new, Tool::FileSystem.new],
          locale: @locale,
          on_inner_monologue: default_on_inner_monologue,
          on_outer_voice: default_on_outer_voice,
          on_action_request: default_on_action_request,
          on_summarize: default_on_summarize
        )
      end

      def format_role
        return @custom_role if @custom_role.present?

        with_locale do
          if @language.present?
            I18n.t('oxaiworkers.assistant.coder.role_with_language', language: @language)
          else
            I18n.t('oxaiworkers.assistant.coder.role')
          end
        end
      end
    end
  end
end
