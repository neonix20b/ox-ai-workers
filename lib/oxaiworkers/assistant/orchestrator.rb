# frozen_string_literal: true

module OxAiWorkers
  module Assistant
    class Orchestrator
      include OxAiWorkers::Assistant::ModuleBase

      def initialize(delayed: false, model: nil, role: nil)
        store_locale

        @pipeline = Tool::Pipeline.new(
          on_message: ->(text:) { @iterator.add_queue text, role: :system }
        )
        @id = 'orchestrator'

        @iterator = Iterator.new(
          worker: init_worker(delayed:, model:),
          role: role || I18n.t('oxaiworkers.assistant.orchestrator.role'),
          tools: [@pipeline],
          locale: @locale,
          on_inner_monologue: ->(text:) { @pipeline.recive_monologue(from_id: @id, message: text) },
          on_outer_voice: ->(text:) { @pipeline.recive_voice(from_id: @id, message: text) }
        )
      end

      def add_assistant(assistant)
        @pipeline.add_assistant(assistant)
      end

      def task=(task)
        @iterator.add_context @pipeline.assistants_info
        super
      end
    end
  end
end
