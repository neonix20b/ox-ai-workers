module OxAiWorkers
  module Tool
    class Pipeline
      include OxAiWorkers::ToolDefinition
      include OxAiWorkers::DependencyHelper
      include OxAiWorkers::LoadI18n

      attr_accessor :assistants, :messages

      def initialize(only: nil, on_message: nil)
        store_locale

        init_white_list_with only

        define_function :send_message, description: I18n.t('oxaiworkers.tool.pipeline.send_message.description') do
          property :message, type: 'string', description: I18n.t('oxaiworkers.tool.pipeline.send_message.message'),
                             required: true
          property :result, type: 'string', description: I18n.t('oxaiworkers.tool.pipeline.send_message.result'),
                            required: true
          property :example, type: 'string', description: I18n.t('oxaiworkers.tool.pipeline.send_message.example')
          property :to_id, type: 'string', description: I18n.t('oxaiworkers.tool.pipeline.send_message.to_id'),
                           required: true
        end

        @messages = []
        @on_message = on_message
      end

      def send_message(message:, result:, example:, to_id:)
        puts "send_message to #{to_id}: #{message}".colorize(:red)
        puts " Result: #{result}"
        puts " Example: #{example}"
        context = context_for(to_id)
        @assistants[to_id].replace_context(context)
        @assistants[to_id].add_task message
        @assistants[to_id].add_task "#{I18n.t('oxaiworkers.tool.pipeline.send_message.result')}: #{result}"
        @assistants[to_id].add_task "#{I18n.t('oxaiworkers.tool.pipeline.send_message.example')}: #{example}"
        @assistants[to_id].execute
        nil
      end

      def add_assistant(assistant)
        unless assistant.id.present? &&
               assistant.title.present? &&
               assistant.role.present? &&
               assistant.description.present? &&
               assistant.capabilities.present?
          raise 'Assistant is not valid: id, title, role, description and capabilities are required'
        end

        assistant.iterator.on_inner_monologue = ->(text:) { recive_monologue(from_id: assistant.id, message: text) }
        assistant.iterator.on_outer_voice = ->(text:) { recive_voice(from_id: assistant.id, message: text) }

        @assistants ||= {}
        @assistants[assistant.id] = assistant
      end

      def recive_monologue(from_id:, message:)
        recive_message(id: from_id, type: 'monologue', message:, color: :yellow)
      end

      def recive_voice(from_id:, message:)
        recive_message(id: from_id, type: 'voice', message:, color: :green)
      end

      def recive_message(id:, type:, message:, color: :grey)
        puts "#{id} [#{type}]: #{message}".colorize(color)
        @messages ||= []
        m = { id:, type:, message: }
        @messages << m
        @on_message.call(text: format_message(m)) if !@on_message.nil? && @assistants.key?(id)
        # @assistants.each_value do |assistant|
        #   assistant.iterator.add_queue format_message(m), role: :system if assistant.id != id
        # end
      end

      def context_for(id)
        array = @messages.select { |message| message[:id] == id || message[:type] == 'voice' }
        array.map { |m| format_message(m) }.join("\n\n")
      end

      def context
        "#{assistants_info}\n\n#{@messages.map { |m| format_message(m) }.join("\n\n")}"
      end

      def assistants_info
        @assistants.values.map { |assistant| format_assistant(assistant) }.join("\n\n")
      end

      def format_message(message)
        "**#{message[:id]}**\n: #{message[:message]}"
      end

      def format_assistant(assistant)
        with_locale do
          I18n.t('oxaiworkers.tool.pipeline.assistant_info',
                 id: assistant.id,
                 title: assistant.title,
                 role: assistant.role,
                 description: assistant.description,
                 capabilities: assistant.capabilities.join(', '))
        end
      end
    end
  end
end
