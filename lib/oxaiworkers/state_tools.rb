# frozen_string_literal: true

require 'state_machine/core'

module OxAiWorkers
  class StateTools
    include OxAiWorkers::StateHelper
    extend StateMachine::MacroMethods

    state_machine :state, initial: :idle do
      before_transition from: any, do: :log_me

      after_transition on: :iterate, do: :next_iteration
      after_transition on: :request, do: :external_request
      after_transition on: :prepare, do: :init
      after_transition on: :analyze, do: :process_result
      after_transition on: :complete, do: :complete_iteration

      event :prepare do
        transition %i[idle finished] => :prepared
      end

      event :request do
        transition prepared: :requested
      end

      event :analyze do
        transition [:requested] => :analyzed
      end

      event :complete do
        transition [:analyzed] => :finished
      end

      event :iterate do
        transition analyzed: :prepared
      end

      event :end do
        transition finished: :idle
      end

      state :idle
      state :prepared
      state :requested
      state :analyzed
      state :finished
    end
  end
end
