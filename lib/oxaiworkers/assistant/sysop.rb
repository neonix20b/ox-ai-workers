# frozen_string_literal: true

module OxAiWorkers
  module Assistant
    class Sysop
      include OxAiWorkers::Assistant::ModuleBase

      def initialize(current_dir: nil, delayed: false, model: nil)
        store_locale

        with_locale do
          @id = 'sysop'
          @role = I18n.t('oxaiworkers.assistant.sysop.role')
          @description = I18n.t('oxaiworkers.assistant.sysop.description')
          @capabilities = I18n.t('oxaiworkers.assistant.sysop.capabilities').split(',').map(&:strip)
          @title = I18n.t('oxaiworkers.assistant.sysop.title')
        end

        @iterator = Iterator.new(
          worker: init_worker(delayed:, model:),
          role: @role,
          tools: [Tool::Eval.new(only: :sh, current_dir:),
                  Tool::FileSystem.new(only: %i[read_file write_to_file], current_dir:)],
          locale: @locale,
          on_inner_monologue: ->(text:) { puts "monologue: #{text}".colorize(:yellow) },
          on_outer_voice: ->(text:) { puts "voice: #{text}".colorize(:green) }
        )
      end
    end
  end
end
