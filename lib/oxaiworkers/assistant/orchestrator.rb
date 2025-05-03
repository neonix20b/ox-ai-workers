# frozen_string_literal: true

module OxAiWorkers
  module Assistant
    class Orchestrator
      include OxAiWorkers::Assistant::ModuleBase

      attr_accessor :workflow

      def initialize(delayed: false, model: nil, role: nil, workflow: nil)
        store_locale

        @pipeline = Tool::Pipeline.new(
          on_message: ->(text:) { @iterator.add_queue text, role: :system }
        )

        with_locale do
          @id = 'orchestrator'
          @role = role || I18n.t('oxaiworkers.assistant.orchestrator.role')
          @description = I18n.t('oxaiworkers.assistant.orchestrator.description')
          @capabilities = I18n.t('oxaiworkers.assistant.orchestrator.capabilities').split(',').map(&:strip)
          @title = I18n.t('oxaiworkers.assistant.orchestrator.title')
          @workflow = I18n.t('oxaiworkers.assistant.orchestrator.workflow_task',
                             workflow_description: workflow)
        end

        @iterator = Iterator.new(
          worker: init_worker(delayed:, model:),
          role: @role,
          tools: [@pipeline],
          locale: @locale,
          on_inner_monologue: ->(text:) { @pipeline.recive_monologue(from_id: @id, message: text) },
          on_outer_voice: ->(text:) { @pipeline.recive_voice(from_id: @id, message: text) }
        )

        @iterator.task = @workflow
      end

      def add_assistant(assistant)
        @pipeline.add_assistant(assistant)
      end
    end
  end
end
