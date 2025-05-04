# frozen_string_literal: true

module OxAiWorkers
  module Assistant
    class Painter
      include OxAiWorkers::Assistant::ModuleBase

      def initialize(current_dir: nil, delayed: false, model: nil)
        store_locale
        @current_dir = current_dir

        with_locale do
          @id = 'painter'
          @role = I18n.t('oxaiworkers.assistant.painter.role')
          @description = I18n.t('oxaiworkers.assistant.painter.description')
          @capabilities = I18n.t('oxaiworkers.assistant.painter.capabilities').split(',').map(&:strip)
          @title = I18n.t('oxaiworkers.assistant.painter.title')
        end

        @iterator = Iterator.new(
          worker: init_worker(delayed:, model:),
          role: @role,
          tools: [Tool::Pixels.new(worker: init_worker(delayed: false, model:), current_dir:)],
          locale: @locale,
          on_inner_monologue: ->(text:) { puts "monologue: #{text}".colorize(:yellow) },
          on_outer_voice: ->(text:) { puts "voice: #{text}".colorize(:green) }
        )
      end

      def cleanup
        Dir.glob(File.join(@current_dir, '*.png')).each do |file|
          File.delete(file) if File.exist?(file)
        end
      end
    end
  end
end
