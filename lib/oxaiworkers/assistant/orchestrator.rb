# frozen_string_literal: true

module OxAiWorkers
  module Assistant
    class Orchestrator
      include OxAiWorkers::Assistant::ModuleBase

      def initialize(title: nil,
                     description: nil,
                     capabilities: nil,
                     delayed: false,
                     model: nil,
                     on_stream: nil)
        store_locale
        with_locale do
          title ||= I18n.t('oxaiworkers.assistant.workspace.orchestrator_title')
          description ||= I18n.t('oxaiworkers.assistant.workspace.orchestrator_description')
          capabilities ||= I18n.t('oxaiworkers.assistant.workspace.orchestrator_capabilities').split(', ')
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
          role: I18n.t('oxaiworkers.assistant.orchestrator.role'),
          tools: [],
          locale: @locale,
          on_inner_monologue: default_on_inner_monologue,
          on_outer_voice: default_on_outer_voice,
          on_action_request: default_on_action_request,
          on_summarize: default_on_summarize
        )
      end

      # Sets information about available assistants
      def set_assistants_info(assistants_info)
        with_locale do
          context = "#{I18n.t('oxaiworkers.assistant.orchestrator.assistant_list_header')}\n\n"
          assistants_info.each do |id, metadata|
            next if id == 'orchestrator'

            context += I18n.t('oxaiworkers.assistant.orchestrator.assistant_info',
                              id:,
                              type: metadata[:type],
                              title: metadata[:title],
                              description: metadata[:description],
                              capabilities: metadata[:capabilities].join(', '))
            context += "\n\n"
          end

          @iterator.add_context(context, role: :system)
        end
      end

      # Sets the workflow
      def set_workflow(workflow_description)
        @iterator.cleanup
        with_locale do
          @iterator.add_task I18n.t('oxaiworkers.assistant.orchestrator.workflow_task',
                                    workflow_description:)
        end
      end

      # Processes the result of a task performed by an assistant
      def process_result(assistant_id, result)
        with_locale do
          @iterator.add_task I18n.t('oxaiworkers.assistant.orchestrator.result_received',
                                    assistant_id:,
                                    result:)
        end
      end
    end
  end
end
