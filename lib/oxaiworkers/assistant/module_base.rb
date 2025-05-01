# frozen_string_literal: true

module OxAiWorkers
  module Assistant
    module ModuleBase
      include OxAiWorkers::LoadI18n

      attr_accessor :iterator

      def task=(task)
        @iterator.cleanup
        @iterator.add_task task
      end

      def add_response(text)
        @iterator.add_task text
      end

      def execute
        @iterator.execute
      end

      def init_worker(delayed: false, model: nil, on_stream: nil)
        worker = delayed ? DelayedRequest.new : Request.new(on_stream:)
        worker.model = model || OxAiWorkers.configuration.model
        worker
      end
    end
  end
end
