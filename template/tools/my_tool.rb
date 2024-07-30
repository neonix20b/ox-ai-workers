# frozen_string_literal: true

class MyTool
  extend OxAiWorkers::ToolDefinition
  include OxAiWorkers::DependencyHelper

  define_function :printHello, description: 'Print hello' do
    property :name, type: 'string', description: 'Your name', required: true
  end

  def printHello(name:)
    puts "Hello #{name}"
  end
end
