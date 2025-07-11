# frozen_string_literal: true

module OxAiWorkers
  class Iterator < OxAiWorkers::StateTools
    ITERATOR_FUNCTIONS = %i[inner_monologue outer_voice finish_it].freeze

    include OxAiWorkers::ToolDefinition
    include OxAiWorkers::LoadI18n

    attr_accessor :worker, :role, :messages, :context, :tools, :queue, :monologue, :tasks,
                  :on_inner_monologue, :on_outer_voice, :on_finish, :def_except, :def_only,
                  :call_stack, :stop_double_calls, :call_id

    def initialize(worker:, role: nil, tools: [], on_inner_monologue: nil, on_outer_voice: nil,
                   on_finish: nil, steps: nil, def_except: [], def_only: nil, locale: nil,
                   call_stack: nil, stop_double_calls: [])

      @locale = locale || I18n.locale
      @call_id = 0

      @def_only = def_only || ITERATOR_FUNCTIONS
      @def_except = def_except

      init_white_list_with available_defs

      with_locale do
        define_function :inner_monologue, description: I18n.t('oxaiworkers.iterator.inner_monologue.description') do
          property :speach, type: 'string', description: I18n.t('oxaiworkers.iterator.inner_monologue.speach'),
                            required: true
        end

        define_function :outer_voice, description: I18n.t('oxaiworkers.iterator.outer_voice.description') do
          property :text, type: 'string', description: I18n.t('oxaiworkers.iterator.outer_voice.text'), required: true
        end

        define_function :finish_it, description: I18n.t('oxaiworkers.iterator.finish_it.description')

        @monologue = steps || I18n.t('oxaiworkers.iterator.monologue')
      end

      @worker = worker
      @tools = tools
      @role = role
      @context = []

      @on_inner_monologue = on_inner_monologue
      @on_outer_voice = on_outer_voice
      @on_finish = on_finish

      if call_stack&.any?
        if available_defs.include?(:inner_monologue) && !call_stack.include?(OxAiWorkers::Iterator.full_function_name(:inner_monologue))
          # Add inner_monologue first
          @call_stack = [OxAiWorkers::Iterator.full_function_name(:inner_monologue)] + call_stack
        end
        # Add finish_it last
        @call_stack = call_stack + [OxAiWorkers::Iterator.full_function_name(:finish_it)]
      end

      @stop_double_calls = [OxAiWorkers::Iterator.full_function_name(:inner_monologue),
                            OxAiWorkers::Iterator.full_function_name(:outer_voice)] + stop_double_calls

      cleanup

      super()

      tick_or_wait if requested?
    end

    #
    # Resets the state of the object by setting all instance variables to their initial values.
    #
    # Returns nothing.
    #
    def cleanup
      @queue = []
      @tasks = []
      @messages = []
      @call_id = 0
      # Очищаем сообщения в worker, если он существует
      @worker.messages = [] if @worker&.respond_to?(:messages=)
      complete_iteration
    end

    # Updates the internal state of the iterator by adding the given `speach` to the `@queue` and calling the `@on_inner_monologue` callback with the `speach` text.
    #
    # @param speach [String] The text to be added to the `@queue` and passed to the `@on_inner_monologue` callback.
    #
    # @return [nil] This method does not return a value.
    def inner_monologue(speach:)
      if available_defs.include?(:inner_monologue)
        @queue << { role: :assistant, content: speach.to_s }
        @on_inner_monologue&.call(text: speach)
      else
        OxAiWorkers.logger.warn "Iterator::inner_monologue is not available: #{speach}"
      end
      speach
    end

    def outer_voice(text:)
      if available_defs.include?(:outer_voice)
        @queue << { role: :assistant, content: text.to_s }
        @on_outer_voice&.call(text:)
      else
        OxAiWorkers.logger.warn "Iterator::outer_voice is not available: #{text}"
        inner_monologue(speach: text)
      end

      text
    end

    def finish_it
      complete! if can_complete?
      @on_finish&.call
      nil
    end

    def init
      rebuild_worker
      request!
    end

    def rebuild_worker
      # @worker.last_call = nil
      @worker.call_stack = @call_stack.dup
      @worker.stop_double_calls = @stop_double_calls
      # Не очищаем сообщения, а сохраняем их в переменной
      current_messages = @worker.messages || []
      @worker.messages = []
      @worker.append(role: :system, content: "<role>\n#{@role}\n</role>") if @role.present?

      @worker.append(role: :system, content: "<instructions>\n#{valid_monologue.join("\n")}\n</instructions>")
      @tasks.each { |task| @worker.append(role: :user, content: "<task>\n#{task}\n</task>") }
      @worker.append(messages: @context) if @context.present?
      @tools.each do |tool|
        @worker.append(role: :user, content: tool.context) if tool.respond_to?(:context) && tool.context.present?
      end
      # Добавляем сохраненные сообщения обратно, если они не пустые
      @worker.append(messages: current_messages) if current_messages.present?
      @worker.append(messages: @messages)
      # @tasks.each { |task| @worker.append(role: :user, content: "<task>\n#{task}\n</task>") }
      @worker.tools = [function_schemas]
      return unless @tools.present?

      @worker.tools += @tools.map do |tool|
        if tool.respond_to?(:function_schemas)
          tool.function_schemas
        else
          tool.class.function_schemas
        end
      end.flatten
    end

    def available_defs
      @def_only - @def_except
    end

    def valid_monologue
      arr = @monologue.reject { |item| @def_except.any? { |fun| item.include?(full_function_name(fun)) } }
      arr.each_with_index.map { |item, index| format(item, index + 1) }
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
      # Проверяем call_stack перед продолжением итерации
      if should_finish_iteration?
        OxAiWorkers.logger.info "Iterator::Call stack is empty or contains only finish_it. Finishing iteration."
        finish_it
        return
      end

      # Сначала добавляем сообщения из очереди к worker
      @worker.append(messages: @queue)
      # Затем добавляем их к локальным сообщениям
      @messages += @queue
      OxAiWorkers.logger.warn "Iterator::Next iteration: #{@messages.count}/#{@queue.count}"
      # И только потом очищаем очередь
      @queue = []
      request!
    end

    def should_finish_iteration?
      return false unless @worker.respond_to?(:call_stack) && @worker.call_stack.present?
      
      finish_it_function = OxAiWorkers::Iterator.full_function_name(:finish_it)
      
      # Проверяем, пуста ли очередь вызовов или содержит только finish_it
      @worker.call_stack.empty? || 
        (@worker.call_stack.size == 1 && @worker.call_stack.first == finish_it_function) ||
        @worker.call_stack.all? { |call| call == finish_it_function }
    end

    def external_request
      @worker.request!
      tick_or_wait
    rescue Faraday::ServerError => e
      OxAiWorkers.logger.warn "Iterator::ServerError #{e.message}. Waiting 10 seconds..."
      sleep(10)
      external_request
    rescue Faraday::BadRequestError => e
      OxAiWorkers.logger.warn "Iterator::BadRequestError #{e.message}."
    end

    def tick_or_wait
      if OxAiWorkers.configuration.wait_for_complete
        wait_for_complete
      else
        ticker
      end
    end

    def ticker
      return false unless @worker.completed?

      analyze!
      true
    end

    def wait_for_complete
      return unless requested?

      sleep(60) unless ticker
    end

    def process_result(_transition)
      # If the response is truncated due to max_tokens, repeat the request
      if @worker.is_truncated && @worker.result.present?
        # Save the partial response and continue the dialogue with AI
        OxAiWorkers.logger.info(
          "Truncated response detected (finish_reason: #{@worker.finish_reason}). Repeating request to get complete response.", for: self.class
        )
        @queue << { role: :assistant, content: @worker.result }
        # Request continuation
        next_iteration
        return
      end

      if @worker.tool_calls.present?
        # @queue << { role: :assistant, content: @worker.tool_calls_raw.to_s }
        @worker.tool_calls.each do |external_call|
          tool = ([self] + @tools).select do |t|
            tool_name = t.respond_to?(:tool_name) ? t.tool_name : t.class.tool_name
            tool_name == external_call[:class] && t.respond_to?(external_call[:name])
          end.first
          next if tool.nil?

          @call_id += 1
          # Add tool call message in the correct format
          OxAiWorkers.logger.info "Iterator::Tool call: #{@call_id}"
          out = tool.send(external_call[:name], **external_call[:args])
          @queue += @worker.model.tool_call(
            name: external_call[:name],
            args: external_call[:args],
            call_id: @call_id,
            out:
          )
        end
        @worker.finish_without_cleanup if @worker.respond_to?(:finish_without_cleanup)
        iterate! if can_iterate?
      end
      result = @worker.result || @worker.errors
      if result.present?
        OxAiWorkers.logger.warn "Iterator::No tool calls: #{result}"
        outer_voice text: result 
      end
    end

    def complete_iteration
      @queue = []
      # Используем finish_without_cleanup вместо finish
      @worker.finish_without_cleanup if @worker.respond_to?(:finish_without_cleanup)
    end

    def add_task(task)
      @tasks << task
    end

    def add_queue(text, role: :assistant)
      @queue << { role:, content: text }
    end

    def add_context(text, role: :user)
      add_raw_context({ role:, content: text })
    end

    def add_file(pdf:, text:, role: :user)
      content = @worker.model.add_base64(binary: pdf, text:, mime_type: 'application/pdf')
      add_raw_context({ role:, content: })
    end

    def add_image(text:, url: nil, binary: nil, role: :user, mime_type: 'image/png')
      content = []
      if binary.present?
        content = @worker.model.add_base64(binary:, text:, mime_type:)
      elsif url.present?
        content = @worker.model.add_url(url:, text:, mime_type:)
      end

      add_raw_context({ role:, content: })
    end

    def add_raw_context(c)
      @context << c
    end

    def clear_context
      @context = []
    end

    def execute
      prepare! if valid?
    end

    def cancel
      @worker.cancel if @worker.respond_to?(:cancel)
    end

    def valid?
      @messages.present? || @tasks.present?
    end
  end
end
