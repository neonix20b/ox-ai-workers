# frozen_string_literal: true

module OxAiWorkers
  module Assistant
    class Sysop
      include OxAiWorkers::Assistant::ModuleBase

      def initialize(delayed: false, model: nil)
        store_locale
        @iterator = Iterator.new(
          worker: init_worker(delayed:, model:),
          role: I18n.t('oxaiworkers.assistant.sysop.role'),
          tools: [Tool::Eval.new(only: :sh), Tool::FileSystem.new(only: %i[read_file write_to_file])],
          locale: @locale,
          on_inner_monologue: ->(text:) { puts "monologue: #{text}".colorize(:yellow) },
          on_outer_voice: ->(text:) { puts "voice: #{text}".colorize(:green) }
        )
      end
    end
  end
end
