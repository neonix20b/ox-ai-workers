module OxAiWorkers
  module Assistant
    class Sysop
      attr_accessor :iterator
      def initialize delayed: false, model: nil
        worker = delayed ? OxAiWorkers::DelayedRequest.new : OxAiWorkers::Request.new
        worker.model = model || OxAiWorkers.configuration.model
        @iterator = OxAiWorkers::Iterator.new(worker: worker, tools: [OxAiWorkers::Tool::Eval.new])
        @iterator.role = I18n.t("oxaiworkers.assistant.sysop.role")
        # @iterator.addTask("покажи мне файлы на диске")
      end
    end
  end
end