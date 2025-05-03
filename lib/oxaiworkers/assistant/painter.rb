# frozen_string_literal: true

module OxAiWorkers
  module Assistant
    class Painter
      include OxAiWorkers::Assistant::ModuleBase

      def initialize(delayed: false, model: nil)
        store_locale

        with_locale do
          @id = 'painter'
          @role = I18n.t('oxaiworkers.assistant.painter.role')
          @description = I18n.t('oxaiworkers.assistant.painter.description')
          @capabilities = I18n.t('oxaiworkers.assistant.painter.capabilities').split(',').map(&:strip)
          @title = I18n.t('oxaiworkers.assistant.painter.title')
        end

        @iterator = ImageIterator.new(
          worker: init_worker(delayed:, model:)
        )
      end
    end
  end
end
