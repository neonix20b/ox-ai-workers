# frozen_string_literal: true

require 'state_machine/core'

module OxAiWorkers
  class StateBatch < OxAiWorkers::ModuleRequest
    include OxAiWorkers::StateHelper
    extend StateMachine::MacroMethods

    alias state_initialize initialize
    attr_accessor :file_id, :batch_id

    state_machine :batch_state, initial: ->(t) { t.batch_id.present? ? :requested : :idle }, namespace: :batch do
      before_transition from: any, do: :log_me

      after_transition on: :end, do: :cleanup
      before_transition on: :process, do: :post_batch
      after_transition on: :cancel, do: %i[cancel_batch complete_batch!]
      after_transition on: :complete, do: [:clean_storage]
      after_transition on: :prepare, do: :upload_to_storage

      event :end do
        transition %i[finished canceled] => :idle
      end

      event :prepare do
        transition idle: :prepared
      end

      event :process do
        transition prepared: :requested
      end

      event :complete do
        transition %i[requested failed] => :finished
      end

      event :cancel do
        transition %i[requested failed prepared] => :canceled
      end

      event :fail do
        transition %i[requested prepared] => :failed
      end

      state :requested
      state :idle
      state :prepared
      state :canceled
      state :finished
      state :failed
    end

    def cleanup
      @file_id = nil
      @batch_id = nil
      super()
    end
  end
end
