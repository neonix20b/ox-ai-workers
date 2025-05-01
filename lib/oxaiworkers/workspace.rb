# frozen_string_literal: true

module OxAiWorkers
  class Workspace
    include OxAiWorkers::LoadI18n

    attr_reader :assistants, :orchestrator

    def initialize(title: nil, description: nil)
      store_locale
      with_locale do
        @title = title || I18n.t('oxaiworkers.assistant.workspace.title')
        @description = description || I18n.t('oxaiworkers.assistant.workspace.description')
      end
      @assistants = {}
      @messages_history = []
      initialize_orchestrator
    end

    # Adds an assistant to the workspace
    def add_assistant(id, assistant)
      with_locale do
        if @assistants.key?(id)
          raise ArgumentError,
                I18n.t('oxaiworkers.assistant.workspace.error_assistant_exists', id:)
        end
        unless assistant.is_a?(OxAiWorkers::Assistant::ModuleBase)
          raise ArgumentError,
                I18n.t('oxaiworkers.assistant.workspace.error_assistant_module')
        end
      end

      @assistants[id] = assistant

      # Update information in the orchestrator about available assistants
      @orchestrator.set_assistants_info(list_assistants) if id != 'orchestrator'
    end

    # Gets an assistant by id
    def get_assistant(id)
      @assistants[id]
    end

    # Removes an assistant from the workspace
    def remove_assistant(id)
      with_locale do
        return false if id == 'orchestrator' # Cannot delete the orchestrator
      end

      @assistants.delete(id)
      # Update information in the orchestrator about available assistants
      @orchestrator.set_assistants_info(list_assistants)
      true
    end

    # Returns a list of all assistants with their metadata
    def list_assistants
      @assistants.transform_values { |assistant| assistant.metadata }
    end

    # Sends a message from one assistant to another
    def send_message(from_id, to_id, message)
      with_locale do
        unless @assistants.key?(from_id)
          raise ArgumentError,
                I18n.t('oxaiworkers.assistant.workspace.error_assistant_not_found',
                       id: from_id)
        end
        unless @assistants.key?(to_id)
          raise ArgumentError,
                I18n.t('oxaiworkers.assistant.workspace.error_assistant_not_found',
                       id: to_id)
        end
      end

      from_assistant = @assistants[from_id]
      to_assistant = @assistants[to_id]

      record_message(from_id, to_id, message)

      # If the recipient is the orchestrator, inform it about the result
      if to_id == 'orchestrator'
        @orchestrator.process_result(from_id, message)
      else
        to_assistant.receive_message(message, from: from_id)
      end
    end

    # Initializes the orchestrator that manages the workflow
    def initialize_orchestrator
      with_locale do
        @orchestrator = OxAiWorkers::Assistant::Orchestrator.new(
          title: I18n.t('oxaiworkers.assistant.workspace.orchestrator_title'),
          description: I18n.t('oxaiworkers.assistant.workspace.orchestrator_description'),
          capabilities: I18n.t('oxaiworkers.assistant.workspace.orchestrator_capabilities').split(', ')
        )
      end

      add_assistant('orchestrator', @orchestrator)
    end

    # Sets the workflow for the orchestrator
    def set_workflow(workflow_description)
      @orchestrator.set_workflow(workflow_description)
    end

    # Gets messages from the exchange history between assistants
    def get_messages_history(from_id: nil, to_id: nil)
      filtered_history = @messages_history
      filtered_history = filtered_history.select { |msg| msg[:from] == from_id } if from_id
      filtered_history = filtered_history.select { |msg| msg[:to] == to_id } if to_id
      filtered_history
    end

    # Executes the next step of the workflow
    def execute_next_step(assistant_response = nil)
      # If there is a response from an assistant, send it to the orchestrator
      if assistant_response
        send_message(assistant_response[:assistant_id], 'orchestrator', assistant_response[:message])
      end

      # Get the next step from the orchestrator
      result = @orchestrator.iterator.result

      if result
        # Parse the orchestrator's result to determine the next step
        # This is simplified logic, a real application would need more complex information extraction
        with_locale do
          assistant_id_pattern = I18n.t('oxaiworkers.assistant.workspace.parse_assistant_id')
          task_pattern = I18n.t('oxaiworkers.assistant.workspace.parse_task')
          expected_result_pattern = I18n.t('oxaiworkers.assistant.workspace.parse_expected_result')

          if result.include?(assistant_id_pattern)
            assistant_id = result.match(/#{Regexp.escape(assistant_id_pattern)}\s*(\w+)/)[1]
            task = result.match(/#{Regexp.escape(task_pattern)}\s*(.+?)(?=#{Regexp.escape(expected_result_pattern)}|$)/m)[1].strip

            if @assistants.key?(assistant_id)
              # Send the task to the specified assistant
              @assistants[assistant_id].task = task
              return {
                status: I18n.t('oxaiworkers.assistant.workspace.status_pending'),
                assistant_id:,
                task:
              }
            else
              return {
                status: I18n.t('oxaiworkers.assistant.workspace.status_error'),
                message: I18n.t('oxaiworkers.assistant.workspace.error_assistant_id_not_found', id: assistant_id)
              }
            end
          else
            return {
              status: I18n.t('oxaiworkers.assistant.workspace.status_completed'),
              message: result
            }
          end
        end
      else
        with_locale do
          return {
            status: I18n.t('oxaiworkers.assistant.workspace.status_waiting'),
            message: I18n.t('oxaiworkers.assistant.workspace.waiting_orchestrator')
          }
        end
      end
    end

    private

    # Records a message in the history
    def record_message(from_id, to_id, message)
      @messages_history << {
        timestamp: Time.now,
        from: from_id,
        to: to_id,
        message:
      }
    end
  end
end
