# frozen_string_literal: true

module OxAiWorkers
  module Assistant
    module ModuleBase
      include OxAiWorkers::LoadI18n

      attr_accessor :iterator, :title, :description, :capabilities

      def initialize(title: nil, description: nil, capabilities: [], delayed: false, model: nil, on_stream: nil)
        @title = title
        @description = description
        @capabilities = capabilities

        store_locale
        initialize_iterator(delayed:, model:, on_stream:)
      end

      def task=(task)
        @iterator.cleanup
        @iterator.add_task task
      end

      def add_response(text)
        @iterator.add_task text
      end

      def execute
        @iterator.execute
      end

      def receive_message(message, from: nil)
        @iterator.cleanup
        if from
          with_locale do
            @iterator.add_context(I18n.t('oxaiworkers.assistant.message_from', from:, message:))
          end
        end
        @iterator.add_task(message)
      end

      def init_worker(delayed: false, model: nil, on_stream: nil)
        worker = delayed ? DelayedRequest.new : Request.new(on_stream:)
        worker.model = model || OxAiWorkers.configuration.model
        worker
      end

      # Абстрактный метод для инициализации итератора, должен быть переопределен в наследниках
      def initialize_iterator(delayed:, model:, on_stream:)
        raise NotImplementedError, 'Subclasses must implement initialize_iterator'
      end

      # Метод для получения метаданных ассистента
      def metadata
        {
          title: @title,
          description: @description,
          capabilities: @capabilities,
          type: self.class.name.split('::').last.downcase
        }
      end

      # Дефолтные колбэки для итератора
      def default_on_inner_monologue
        lambda do |text:|
          caller_info = caller_locations(1, 1).first
          with_locale do
            puts "#{I18n.t('oxaiworkers.callbacks.monologue')} [#{caller_info}]: #{text}".colorize(:yellow)
          end
        end
      end

      def default_on_outer_voice
        lambda do |text:|
          caller_info = caller_locations(1, 1).first
          with_locale do
            puts "#{I18n.t('oxaiworkers.callbacks.voice')} [#{caller_info}]: #{text}".colorize(:green)
          end
        end
      end

      def default_on_action_request
        lambda do |text:|
          caller_info = caller_locations(1, 1).first
          with_locale do
            puts "#{I18n.t('oxaiworkers.callbacks.action')} [#{caller_info}]: #{text}".colorize(:red)
          end
        end
      end

      def default_on_summarize
        lambda do |text:|
          caller_info = caller_locations(1, 1).first
          with_locale do
            puts "#{I18n.t('oxaiworkers.callbacks.summary')} [#{caller_info}]: #{text}".colorize(:blue)
          end
        end
      end
    end
  end
end
