# frozen_string_literal: true

module OxAiWorkers
  module Assistant
    class Sysop
      include OxAiWorkers::Assistant::ModuleBase

      def initialize(title: nil,
                     description: nil,
                     capabilities: nil,
                     delayed: false,
                     model: nil,
                     on_stream: nil)
        store_locale
        with_locale do
          title ||= I18n.t('oxaiworkers.assistant.sysop.title')
          description ||= I18n.t('oxaiworkers.assistant.sysop.description')
          capabilities ||= I18n.t('oxaiworkers.assistant.sysop.capabilities').split(', ')
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
          tools: [Tool::Eval.new(only: :sh), Tool::FileSystem.new(only: %i[read_file write_to_file])],
          locale: @locale,
          on_inner_monologue: default_on_inner_monologue,
          on_outer_voice: default_on_outer_voice,
          on_action_request: default_on_action_request,
          on_summarize: default_on_summarize
        )
      end

      def format_role
        with_locale do
          I18n.t('oxaiworkers.assistant.sysop.role')
        end
      end
    end
  end
end
