# frozen_string_literal: true

module OxAiWorkers
  module Assistant
    class Coder
      include OxAiWorkers::Assistant::ModuleBase

      def initialize(delayed: false, model: nil, language: 'ruby')
        store_locale

        with_locale do
          @id = 'coder'
          @role = format(I18n.t('oxaiworkers.assistant.coder.role'), language)
          @description = I18n.t('oxaiworkers.assistant.coder.description')
          @capabilities = I18n.t('oxaiworkers.assistant.coder.capabilities').split(',').map(&:strip)
          @title = I18n.t('oxaiworkers.assistant.coder.title')
        end

        @iterator = Iterator.new(
          worker: init_worker(delayed:, model:),
          role: @role,
          tools: [Tool::Eval.new, Tool::FileSystem.new],
          locale: @locale,
          on_inner_monologue: ->(text:) { puts "monologue: #{text}".colorize(:yellow) },
          on_outer_voice: ->(text:) { puts "voice: #{text}".colorize(:green) }
        )
      end

      def language=(language)
        with_locale do
          @role = format(I18n.t('oxaiworkers.assistant.coder.role'), language)
          @iterator.role = @role
        end
      end
    end
  end
end
