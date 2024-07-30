# frozen_string_literal: true

module OxAiWorkers
  class Iterator < OxAiWorkers::StateTools
    extend OxAiWorkers::ToolDefinition
    attr_accessor :worker, :role, :messages, :context, :result, :tools, :queue, :monologue, :tasks, :milestones
    attr_accessor :on_inner_monologue, :on_outer_voice, :on_action_request, :on_pack_history

    define_function :innerMonologue, description: I18n.t('oxaiworkers.iterator.inner_monologue.description') do
      property :speach, type: 'string', description: I18n.t('oxaiworkers.iterator.inner_monologue.speach'),
                        required: true
    end

    define_function :outerVoice, description: I18n.t('oxaiworkers.iterator.outer_voice.description') do
      property :text, type: 'string', description: I18n.t('oxaiworkers.iterator.outer_voice.text'), required: true
    end

    define_function :actionRequest, description: I18n.t('oxaiworkers.iterator.action_request.description') do
      property :action, type: 'string', description: I18n.t('oxaiworkers.iterator.action_request.action'),
                        required: true
    end

    define_function :packHistory, description: I18n.t('oxaiworkers.iterator.pack_history.description') do
      property :text, type: 'string', description: I18n.t('oxaiworkers.iterator.pack_history.text'), required: true
    end

    def initialize(worker:, role: nil, tools: [], on_inner_monologue: nil, on_outer_voice: nil, on_action_request: nil,
                   on_pack_history: nil)
      puts "call: #{__method__}"
      @worker = worker
      @tools = [self] + tools
      @role = role
      @context = nil
      @monologue = I18n.t('oxaiworkers.iterator.monologue')

      @on_inner_monologue = on_inner_monologue
      @on_outer_voice = on_outer_voice
      @on_action_request = on_action_request
      @on_pack_history = on_pack_history

      cleanup

      super()
    end

    def cleanup
      @result = nil
      @queue = []
      @tasks = []
      @milestones = []
      @messages = []
      completeIteration
    end

    def innerMonologue(speach:)
      @queue.pop
      @queue << { role: :system, content: "#{__method__}: #{speach}" }
      @on_inner_monologue&.call(text: speach)
      nil
    end

    def outerVoice(text:)
      @queue.pop
      @queue << { role: :system, content: "#{__method__}: #{text}" }
      @on_outer_voice&.call(text: text)
      nil
    end

    def actionRequest(action:)
      @result = action
      @queue.pop
      @messages << { role: :system, content: "#{__method__}: #{action}" }
      complete! if can_complete?
      @on_action_request&.call(text: action)
      nil
    end

    def packHistory(text:)
      @milestones << "#{__method__}: #{text}"
      @messages = []
      @worker.finish
      rebuildWorker
      complete! if can_complete?
      @on_pack_history&.call(text: text)
      nil
    end

    def init
      puts "call: #{__method__} state: #{state_name}"
      rebuildWorker
      request!
    end

    def rebuildWorker
      @worker.messages = []
      @worker.append(role: :system, content: @role) if !@role.nil? && @role.present?
      @worker.append(role: :system, content: @monologue.join("\n"))
      @worker.append(messages: @context) if !@context.nil? and @context.any?
      @tasks.each { |task| @worker.append(role: :user, content: task) }
      @milestones.each { |milestone| @worker.append(role: :system, content: milestone) }
      @worker.append(messages: @messages)
      @worker.tools = @tools.map { |tool| tool.class.function_schemas.to_openai_format }.flatten if @tools.any?
    end

    def nextIteration
      puts "call: #{__method__} state: #{state_name}"
      @worker.append(messages: @queue)
      @messages += @queue
      @queue = []
      request!
    end

    def externalRequest
      puts "call: #{__method__} state: #{state_name}"
      @worker.request!
      ticker
    end

    def ticker
      puts "call: #{__method__} state: #{state_name}"
      sleep(60) until @worker.completed?
      analyze!
    end

    def processResult(_transition)
      puts "call: #{__method__} state: #{state_name}"
      @result = @worker.result || @worker.errors
      if @worker.tool_calls.present?
        @queue << { role: :system, content: @worker.tool_calls_raw.to_s }
        @worker.tool_calls.each do |external_call|
          tool = @tools.select do |t|
            t.class.tool_name == external_call[:class] && t.respond_to?(external_call[:name])
          end.first
          unless tool.nil?
            out = tool.send(external_call[:name], **external_call[:args])
            @queue << { role: :system, content: out.to_s } if out.present?
          end
        end
        @worker.finish
        iterate! if can_iterate?

        # tool = @tools.select{|t| t.class.tool_name == @worker.external_call[:class] && t.respond_to?(@worker.external_call[:name]) }.first
        # out = tool.send(@worker.external_call[:name], **@worker.external_call[:args])
        # if can_iterate?
        #   @queue << {role: :system, content: out.to_s} if out.present?
        #   iterate!
        # end
      elsif @worker.result.present?
        actionRequest action: @worker.result
      end
    end

    def completeIteration
      @queue = []
      @worker.finish
    end

    def addTask(task, auto_execute: true)
      @tasks << task
      @messages << { role: :user, content: task }
      execute if auto_execute
    end

    def appendContext(text, role: :system)
      @context << { role: role, content: text }
    end

    def execute
      puts "call: #{__method__} state: #{state_name}"
      prepare! if valid?
    end

    def cancel
      puts "call: #{__method__} state: #{state_name}"
      @worker.cancel if @worker.respond_to?(:cancel)
    end

    def valid?
      @messages.any?
    end
  end
end
