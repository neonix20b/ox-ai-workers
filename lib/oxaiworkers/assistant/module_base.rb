module OxAiWorkers
  module Assistant
    module ModuleBase
      attr_accessor :iterator

      def setTask(task)
        @iterator.cleanup
        @iterator.addTask task
      end

      def addResponse(text)
        @iterator.addTask text
      end

      def initWorker(delayed:, model:)
        worker = delayed ? DelayedRequest.new : Request.new
        worker.model = model || OxAiWorkers.configuration.model
        worker
      end
    end
  end
end
