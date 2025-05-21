# frozen_string_literal: true

module OxAiWorkers
  module Assistant
    module ModuleBase
      include OxAiWorkers::LoadI18n

      attr_accessor :iterator, :role, :description, :capabilities, :id, :title

      def task=(task)
        @iterator.cleanup
        @iterator.add_task task
      end

      def add_task(text)
        @iterator.add_task text
      end

      def execute
        @iterator.execute
      end

      def run_task(text)
        self.task = text
        execute
      end

      def init_worker(delayed: false, model: nil)
        model ||= OxAiWorkers.default_model
        delayed ? DelayedRequest.new(model:) : Request.new(model:)
      end

      def replace_context(context)
        @iterator.clear_context
        @iterator.add_context context
      end

      def add_file(pdf:, filename:, text:, role: :user)
        @iterator.add_file(pdf:, filename:, text:, role:)
      end

      def add_image(text:, url: nil, binary: nil, role: :user, detail: 'auto', mime_type: 'image/jpeg')
        @iterator.add_image(text:, url:, binary:, role:, detail:, mime_type:)
      end
    end
  end
end
