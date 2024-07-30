# frozen_string_literal: true

class MyTool
  extend OxAiWorkers::ToolDefinition
  include OxAiWorkers::DependencyHelper

  define_function :sh, description: 'Execute a sh command and get the result (stdout + stderr)' do
    property :input, type: 'string', description: 'Source command', required: true
  end

  def sh(input:)
    puts "Executing sh: \"#{input}\""
    stdout_and_stderr_s, = Open3.capture2e(input)
    stdout_and_stderr_s
  end
end
