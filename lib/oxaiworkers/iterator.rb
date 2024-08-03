# frozen_string_literal: true

module OxAiWorkers
  class Iterator < OxAiWorkers::StateTools
    ITERATOR_FUNCTIONS = %i[inner_monologue outer_voice action_request summarize].freeze

    include OxAiWorkers::ToolDefinition
    include OxAiWorkers::LoadI18n

    attr_accessor :worker, :role, :messages, :context, :result, :tools, :queue, :monologue, :tasks, :milestones,
                  :on_inner_monologue, :on_outer_voice, :on_action_request, :on_summarize, :def_except, :def_only

    def initialize(worker:, role: nil, tools: [], on_inner_monologue: nil, on_outer_voice: nil, on_action_request: nil,
                   on_summarize: nil, steps: nil, def_except: [], def_only: nil, locale: nil)

      @locale = locale || I18n.locale

      with_locale do
        define_function :inner_monologue, description: I18n.t('oxaiworkers.iterator.inner_monologue.description') do
          property :speach, type: 'string', description: I18n.t('oxaiworkers.iterator.inner_monologue.speach'),
                            required: true
        end

        define_function :outer_voice, description: I18n.t('oxaiworkers.iterator.outer_voice.description') do
          property :text, type: 'string', description: I18n.t('oxaiworkers.iterator.outer_voice.text'), required: true
        end

        define_function :action_request, description: I18n.t('oxaiworkers.iterator.action_request.description') do
          property :action, type: 'string', description: I18n.t('oxaiworkers.iterator.action_request.action'),
                            required: true
        end

        define_function :summarize, description: I18n.t('oxaiworkers.iterator.summarize.description') do
          property :text, type: 'string', description: I18n.t('oxaiworkers.iterator.summarize.text'), required: true
        end

        @monologue = steps || I18n.t('oxaiworkers.iterator.monologue')
      end

      @worker = worker
      @tools = tools
      @role = role
      @context = []
      @def_only = def_only || ITERATOR_FUNCTIONS
      @def_except = def_except

      @on_inner_monologue = on_inner_monologue
      @on_outer_voice = on_outer_voice
      @on_action_request = on_action_request
      @on_summarize = on_summarize

      cleanup

      super()
    end

    def cleanup
      @result = nil
      @queue = []
      @tasks = []
      @milestones = []
      @messages = []
      complete_iteration
    end

    def inner_monologue(speach:)
      # @queue.pop
      @queue << { role: :assistant, content: speach.to_s }
      @on_inner_monologue&.call(text: speach)
      nil
    end

    def outer_voice(text:)
      # @queue.pop
      @queue << { role: :assistant, content: text.to_s }
      complete! unless available_defs.include?(:action_request)
      @on_outer_voice&.call(text: text)
      nil
    end

    def action_request(action:)
      @result = action
      # @queue.pop
      @messages << { role: :assistant, content: action.to_s }
      complete! if can_complete?
      @on_action_request&.call(text: action)
      nil
    end

    def summarize(text:)
      @milestones << text.to_s
      @messages = []
      with_locale do
        @queue << { role: :assistant, content: I18n.t('oxaiworkers.iterator.summarize.result') }
      end
      @worker.finish
      rebuild_worker
      complete! if can_complete?
      @on_summarize&.call(text: text)
      nil
    end

    def init
      rebuild_worker
      request!
    end

    def rebuild_worker
      @worker.messages = []
      @worker.append(role: :system, content: @role) if @role.present?
      @worker.append(role: :system, content: valid_monologue.join("\n"))
      @worker.append(messages: @context) if @context.present?
      @tasks.each { |task| @worker.append(role: :user, content: task) }
      @milestones.each { |milestone| @worker.append(role: :assistant, content: milestone) }
      @worker.append(messages: @messages)
      @worker.tools = function_schemas.to_openai_format(only: available_defs)
      return unless @tools.present?

      @worker.tools += @tools.map do |tool|
        if tool.respond_to?(:function_schemas)
          tool.function_schemas.to_openai_format
        else
          tool.class.function_schemas.to_openai_format
        end
      end.flatten
    end

    def available_defs
      @def_only - @def_except
    end

    def valid_monologue
      @monologue.reject { |item| @def_except.any? { |fun| item.include?(full_function_name(fun)) } }
    end

    def tool_name
      @tool_name ||= (respond_to?(:name) ? name : self.class.name)
                     .gsub('::', '_')
                     .gsub(/(?<=[A-Z])(?=[A-Z][a-z])|(?<=[a-z\d])(?=[A-Z])/, '_')
                     .downcase
    end

    def self.full_function_name(fun)
      tool_name ||= name
                    .gsub('::', '_')
                    .gsub(/(?<=[A-Z])(?=[A-Z][a-z])|(?<=[a-z\d])(?=[A-Z])/, '_')
                    .downcase

      "#{tool_name}__#{fun}"
    end

    def next_iteration
      @worker.append(messages: @queue)
      @messages += @queue
      @queue = []
      request!
    end

    def external_request
      @worker.request!
      ticker
    end

    def ticker
      sleep(60) until @worker.completed?
      analyze!
    end

    def process_result(_transition)
      @result = @worker.result || @worker.errors
      if @worker.tool_calls.present?
        @queue << { role: :assistant, content: @worker.tool_calls_raw.to_s }
        @worker.tool_calls.each do |external_call|
          tool = ([self] + @tools).select do |t|
            tool_name = t.respond_to?(:tool_name) ? t.tool_name : t.class.tool_name
            tool_name == external_call[:class] && t.respond_to?(external_call[:name])
          end.first
          unless tool.nil?
            out = tool.send(external_call[:name], **external_call[:args])
            @queue << { role: :system, content: out.to_s } if out.present?
          end
        end
        @worker.finish
        iterate! if can_iterate?
      elsif @worker.result.present?
        action_request action: @worker.result
      end
    end

    def complete_iteration
      @queue = []
      @worker.finish
    end

    def add_task(task)
      @tasks << task
      @messages << { role: :user, content: task }
      execute if OxAiWorkers.configuration.auto_execute
    end

    def add_context(text, role: :system)
      @context << { role: role, content: text }
    end

    def execute
      prepare! if valid?
    end

    def cancel
      @worker.cancel if @worker.respond_to?(:cancel)
    end

    def valid?
      @messages.present? || @milestones.present?
    end
  end
end
