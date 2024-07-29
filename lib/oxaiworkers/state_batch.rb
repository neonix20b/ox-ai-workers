require 'state_machine/core'

class OxAiWorkers::StateBatch < OxAiWorkers::ModuleRequest
  include OxAiWorkers::StateHelper
  extend StateMachine::MacroMethods

  alias_method :state_initialize, :initialize
  attr_accessor :file_id, :batch_id

  state_machine :batch_state, initial: ->(t){t.batch_id.present? ? :requested : :idle}, namespace: :batch do
    before_transition from: any, do: :log_me

    after_transition on: :end, do: :cleanup
    before_transition on: :process, do: :postBatch
    after_transition on: :cancel, do: [:cancelBatch, :complete_batch!]
    after_transition on: :complete, do: [:cleanStorage]
    after_transition on: :prepare, do: :uploadToStorage

    event :end do
      transition [:finished, :canceled] => :idle
    end

    event :prepare do
      transition :idle => :prepared
    end

    event :process do
      transition :prepared => :requested
    end

    event :complete do
      transition [:requested, :failed] => :finished
    end

    event :cancel do
      transition [:requested, :failed, :prepared] => :canceled
    end

    event :fail do
      transition [:requested, :prepared] => :failed
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

  def initialize
    puts "call: StateBatch::#{__method__}"
    super()
  end
end