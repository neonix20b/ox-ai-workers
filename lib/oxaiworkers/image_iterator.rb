# frozen_string_literal: true

module OxAiWorkers
  class ImageIterator
    attr_accessor :worker, :on_inner_monologue, :on_outer_voice, :on_finish, :task

    def initialize(worker:, on_inner_monologue: nil, on_outer_voice: nil, on_finish: nil)
      @worker = worker
      @on_inner_monologue = on_inner_monologue
      @on_outer_voice = on_outer_voice
      @on_finish = on_finish
    end

    def execute
      response = @worker.client.images.generate(
        parameters: {
          prompt: @task,
          model: 'dall-e-3',
          size: '1024x1792',
          quality: 'standard'
        }
      )

      puts response.dig('data', 0, 'url')
    end

    def cleanup
      @worker.cleanup
    end

    def add_task(task)
      @task = task
    end
  end
end
