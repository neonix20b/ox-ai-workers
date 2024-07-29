class OxAiWorkers::Iterator < OxAiWorkers::StateTools
  extend OxAiWorkers::ToolDefinition
  attr_accessor :worker, :role, :messages, :context, :result, :tools, :queue, :monologue, :tasks, :milestones

  define_function :innerMonologue, description: I18n.t("oxaiworkers.iterator.inner_monologue.description") do
    property :speach, type: "string", description: I18n.t("oxaiworkers.iterator.inner_monologue.speach"), required: true
  end

  define_function :outerVoice, description: I18n.t("oxaiworkers.iterator.outer_voice.description") do
    property :text, type: "string", description: I18n.t("oxaiworkers.iterator.outer_voice.text"), required: true
  end

  define_function :actionRequest, description: I18n.t("oxaiworkers.iterator.action_request.description") do
    property :action, type: "string", description: I18n.t("oxaiworkers.iterator.action_request.action"), required: true
  end

  define_function :packHistory, description: I18n.t("oxaiworkers.iterator.pack_history.description") do
    property :text, type: "string", description: I18n.t("oxaiworkers.iterator.pack_history.text"), required: true
  end

  def initialize(worker:, role: nil, tools: [])
    puts "call: #{__method__}"
    @worker = worker
    @messages = []
    @tools = [self] + tools
    @role = role
    @context = nil
    @result = nil
    @queue = []
    @monologue = I18n.t("oxaiworkers.iterator.monologue")
    @tasks = []
    @milestones = []

    # @tools = OxAiWorkers::Tool.constants.map(&OxAiWorkers::Tool.method(:const_get)).select { |c| c.is_a? Class }.map{|c|c.new}
    super()
  end

  def innerMonologue speach:
    puts Rainbow("monologue: #{speach}").yellow
    @queue.pop
    @queue << {role: :system, content: "#{__method__}: #{speach}"}
    return nil
  end

  def outerVoice text:
    puts Rainbow("voice: #{text}").green
    @queue.pop
    @queue << {role: :system, content:  "#{__method__}: #{text}"}
    return nil
  end

  def actionRequest action:
    puts Rainbow("action: #{action}").red
    @result = action
    @queue.pop
    @messages << {role: :system, content:  "#{__method__}: #{action}"}
    complete! if can_complete?
    return nil
  end

  def packHistory text:
    puts Rainbow("summarize: #{text}").blue
    @milestones << "#{Time.now} #{__method__}: #{text}"
    @messages = []
    @worker.finish()
    rebuildWorker()
    complete! if can_complete?
    return nil
  end

  def init
    puts "call: #{__method__} state: #{state_name}"
    rebuildWorker()
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
    @worker.request!()
    ticker()
  end

  def ticker
    puts "call: #{__method__} state: #{state_name}"
    while !@worker.completed? do 
      sleep(60) 
    end
    analyze!
  end

  def processResult(transition)
    puts "call: #{__method__} state: #{state_name}"
    @result = @worker.result || @worker.errors
    if @worker.external_call.present?
      @queue << {role: :system, content: @worker.tool_calls_raw.to_s}
      @worker.tool_calls.each do |external_call|
        tool = @tools.select{|t| t.class.tool_name == external_call[:class] && t.respond_to?(external_call[:name]) }.first
        unless tool.nil?
          out = tool.send(external_call[:name], **external_call[:args])
          @queue << {role: :system, content: out.to_s} if out.present?
        end
      end
      iterate! if can_iterate?

      # tool = @tools.select{|t| t.class.tool_name == @worker.external_call[:class] && t.respond_to?(@worker.external_call[:name]) }.first
      # out = tool.send(@worker.external_call[:name], **@worker.external_call[:args])
      # if can_iterate?
      #   @queue << {role: :system, content: out.to_s} if out.present?
      #   iterate!
      # end
    elsif @result.present?
        actionRequest action: @result
    end
  end

  def completeIteration
    @worker.finish()
  end
  
  def addTask task, auto_execute: true
    @tasks << task
    @messages << {role: :user, content: task}
    task
    execute() if auto_execute
  end

  def appendContext text, role: :system
    @context << {role: role, content: text}
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
