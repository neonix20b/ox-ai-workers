module OxAiWorkers
  module Assistant
    class Sysop
      include OxAiWorkers::Assistant::ModuleBase

      def initialize delayed: false, model: nil
        @iterator = OxAiWorkers::Iterator.new(
            worker: initWorker(delayed: delayed, model: model),
            role: I18n.t("oxaiworkers.assistant.sysop.role"),
            tools: [OxAiWorkers::Tool::Eval.new]
          )
      end
    end
  end
end