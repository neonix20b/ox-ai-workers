# frozen_string_literal: true

module OxAiWorkers
  module Assistant
    class Expert
      include OxAiWorkers::Assistant::ModuleBase

      def initialize(delayed: false, model: nil, location: nil)
        store_locale

        with_locale do
          @id = 'expert'
          @role = I18n.t('oxaiworkers.assistant.expert.role')
          @description = I18n.t('oxaiworkers.assistant.expert.description')
          @capabilities = I18n.t('oxaiworkers.assistant.expert.capabilities').split(',').map(&:strip)
          @title = I18n.t('oxaiworkers.assistant.expert.title')
        end

        worker = init_worker(delayed:, model:)
        tool = Tool::Wolfram.new(location:)

        @iterator = Iterator.new(
          worker:,
          role: @role,
          tools: [tool],
          # call_stack: [
          #   OxAiWorkers::Iterator.full_function_name(:inner_monologue),
          #   tool.full_function_name(:ask),
          #   OxAiWorkers::Iterator.full_function_name(:outer_voice)
          # ],
          locale: @locale,
          on_inner_monologue: ->(text:) { puts "monologue: #{text}".colorize(:yellow) },
          on_outer_voice: ->(text:) { puts "voice: #{text}".colorize(:green) }
        )
      end
    end
  end
end
