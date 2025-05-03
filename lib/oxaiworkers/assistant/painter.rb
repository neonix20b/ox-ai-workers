# frozen_string_literal: true

module OxAiWorkers
  module Assistant
    class Painter
      include OxAiWorkers::Assistant::ModuleBase

      def initialize(tmp_dir:, delayed: false, model: nil)
        store_locale
        @tmp_dir = tmp_dir

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
          tools: [Tool::Pixels.new(worker: init_worker(delayed: false, model:), tmp_dir:)],
          locale: @locale,
          on_inner_monologue: ->(text:) { puts "monologue: #{text}".colorize(:yellow) },
          on_outer_voice: ->(text:) { puts "voice: #{text}".colorize(:green) }
        )

        # Register finalizer to cleanup PNG files when object is destroyed
        ObjectSpace.define_finalizer(self, self.class.finalize(@tmp_dir))
      end

      # Class method that returns a proc for the finalizer
      def self.finalize(tmp_dir)
        proc {
          Dir.glob(File.join(tmp_dir, '*.png')).each do |file|
            File.delete(file) if File.exist?(file)
          end
        }
      end

      def cleanup
        Dir.glob(File.join(@tmp_dir, '*.png')).each do |file|
          File.delete(file) if File.exist?(file)
        end
      end
    end
  end
end
