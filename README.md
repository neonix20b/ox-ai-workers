# OxAiWorkers (ox-ai-workers)

[![Gem Version](https://badge.fury.io/rb/ox-ai-workers.svg)](https://rubygems.org/gems/ox-ai-workers)

OxAiWorkers is a Ruby gem that implements a finite state machine (using the `state_machine` gem) to solve tasks using generative intelligence (with the `ruby-openai` gem). This approach enhances the final result by utilizing internal monologue and external tools.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ox-ai-workers'
```

And then execute:

```sh
bundle install
```

Or install it yourself as:

```sh
gem install ox-ai-workers
```

## Usage

Here's a basic example of how to use OxAiWorkers:

```ruby
# Load localization files and set default locale
# Uncomment this if you want to change the locale
# require 'oxaiworkers/load_i18n' # only for pure Ruby
# I18n.default_locale = :ru       # only for pure Ruby

# Require the main gem
require 'ox-ai-workers'

# Initialize the assistant
sysop = OxAiWorkers::Assistant::Sysop.new(delayed: false, model: "gpt-4o")

# Add a task to the assistant
sysop.task = "Add a cron job to synchronize files daily."

# Provide a response to the assistant's question
sysop.add_response("blah-blah-blah")
```

Alternatively, you can use a lower-level approach for more control:

```ruby
# Initialize a worker for delayed requests
worker = OxAiWorkers::DelayedRequest.new(
    model: "gpt-4o-mini", 
    max_tokens: 4096, 
    temperature: 0.7 )

# Alternatively, initialize a worker for immediate requests
worker = OxAiWorkers::Request.new(
    model: "gpt-4o-mini", 
    max_tokens: 4096, 
    temperature: 0.7 )

# Initialize a tool
my_tool = OxAiWorkers::Tool::Eval.new(only: :sh)

# Create an iterator with the worker and tool
iterator = OxAiWorkers::Iterator.new(
    worker: worker, 
    tools: [my_tool] )
iterator.role = "You are a software agent inside my computer"

# Add a task to the iterator
iterator.add_task("Show files in current dir")

# Provide a response to the gpt's question
iterator.add_task("linux")
```

### With Config

For a more robust setup, you can configure the gem with your API keys, for example in an oxaiworkers.rb initializer file. Never hardcode secrets into your codebase - instead use something like [dotenv](https://github.com/motdotla/dotenv) to pass the keys safely into your environments.

```ruby
OxAiWorkers.configure do |config|
    config.access_token = ENV.fetch("OPENAI")
    config.model = "gpt-4o"
    config.max_tokens = 4096   # Default
    config.temperature = 0.7   # Default
    config.auto_execute = true # Default
    config.wait_for_complete = true # Default
end
```

Then you can create an assistant like this:

```ruby
assistant = OxAiWorkers::Assistant::Sysop.new()
assistant.task = "Remove all cron jobs."
# assistant.execute # if auto_execute is false

# Provide a response to the assistant's question
assistant.add_response("blah-blah-blah")
# assistant.execute # if auto_execute is false
```

Besides, you can create assistants with different locales

```ruby
I18n.with_locale(:en) { @sysop_en = OxAiWorkers::Assistant::Sysop.new() }

# Assign tasks and responses in different languages
@sysop_en.task = "Remove all cron jobs."
```

Or you can create a lower-level iterator for more control:

```ruby
my_worker = OxAiWorkers::Request.new
my_tool = OxAiWorkers::Tool::Eval.new(only: [:sh])

iterator = OxAiWorkers::Iterator.new(
    worker: my_worker, 
    tools: [my_tool],
    role: "You are a software agent inside my computer",
    on_inner_monologue: ->(text:) { puts "monologue: #{text}".colorize(:yellow) },
    on_outer_voice: ->(text:) { puts "voice: #{text}".colorize(:green) },
    on_action_request: ->(text:) { puts "action: #{text}".colorize(:red) },
    on_summarize: ->(text:) { puts "summary: #{text}".colorize(:blue) },
    on_finish: -> { puts "finish".colorize(:magenta) }
  )

iterator.add_task("Show files in current directory.")
# ...
iterator.add_task("linux")
```

If `auto_execute` is set to false in the configuration, don't forget to manually execute the iterator or assistant.

```ruby
iterator.execute # if auto_execute is false
```

This way, you have the flexibility to choose between a higher-level assistant for simplicity or a lower-level iterator for finer control over the tasks and tools used.

### Advanced instructions for your Assistant

```ruby
steps = []
steps << 'Step 1. Develop your own solution to the problem, taking initiative and making assumptions.'
steps << "Step 2. Enclose all your developments from the previous step in the #{OxAiWorkers::Iterator.full_function_name(:inner_monologue)} function."
steps << 'Step 3. Call the necessary functions one after another until the desired result is achieved.'
steps << "Step 4. When all intermediate steps are completed and the exact content of previous messages is no longer relevant, use the #{OxAiWorkers::Iterator.full_function_name(:summarize)} function."
steps << "Step 5. When the solution is ready, notify about it and wait for the user's response."

# To retain the locale if you have assistants in different languages in your project.
store_locale # Optional

@iterator = OxAiWorkers::Iterator.new(
  worker: init_worker(delayed: delayed, model: model),
  role: 'You are a software agent inside my computer',
  tools: [MyTool.new],
  locale: @locale || I18n.locale,
  steps: steps,
  # def_except: [:summarize], # It's except steps with that functions
  # def_only: [:inner_monologue, :outer_voice], # Use it only with your steps
  on_inner_monologue: ->(text:) { puts "monologue: #{text}".colorize(:yellow) },
  on_outer_voice: ->(text:) { puts "voice: #{text}".colorize(:green) },
  on_action_request: ->(text:) { puts "action: #{text}".colorize(:red) },
  on_summarize: ->(text:) { puts "summary: #{text}".colorize(:blue) }
)
```

### Worker Options

As a worker, you can use different classes depending on your needs:

- `OxAiWorkers::Request`: This class is used for immediate request execution. It is suitable for operations that require instant responses.

- `OxAiWorkers::DelayedRequest`: This class is used for batch API requests, ideal for operations that do not require immediate execution. Using `DelayedRequest` can save up to 50% on costs as requests are executed when the remote server is less busy, but no later than within 24 hours.

### Alternative Models

OxAiWorkers supports alternative compatible models like DeepSeek. To use these models, specify the appropriate base URI in the initializer:

```ruby
worker = OxAiWorkers::Request.new(
    model: "deepseek-chat",
    uri_base: "https://api.deepseek.com/"
)

# Or with configuration
OxAiWorkers.configure do |config|
    config.uri_base = "https://api.deepseek.com/"
    config.model = "deepseek-chat"
    # Other configuration options...
end
```

This allows you to use any API-compatible LLM provider by simply changing the base URI.

### Rails Projects with DelayedRequest

Generate your model to store the `batch_id` in the database:

```bash
rails generate model MyRequestWithStore batch_id:string
```

In your `app/models/my_request_with_store.rb` file, add the following code:

```ruby
class MyRequestWithStore < ApplicationRecord
  def delayed_request
    @worker ||= OxAiWorkers::DelayedRequest.new(batch_id: self.batch_id)
  end
end
```

Then you can use the iterator like this:

```ruby
# Fetch the first stored batch
my_store = MyRequestWithStore.first

# Get the worker
my_worker = my_store.delayed_request

# Create the iterator
iterator = OxAiWorkers::Iterator.new(worker: my_worker)
# ... use the iterator

# Destroy the store after completion
my_store.destroy if my_worker.completed?
```

To store your batches in the database, use the following code:

```ruby
# Get the worker from the iterator
my_worker = iterator.worker

# Store the batch_id if it's not completed
unless my_worker.completed?
  my_store = MyRequestWithStore.create!(batch_id: my_worker.batch_id)
end
```

## Command Line Interface (CLI)

1. Navigate to the required directory.

2. Initialize with the command:

    ```sh
    oxaiworkers init
    ```

    This will create a `.oxaiworkers-local` directory with the necessary initial source code.

    Additionally, you can initialize a more comprehensive example using the command:

    ```sh
    oxaiworkers init full
    ```

    After this, in the `my_assistant.rb` file, you can find an example of an assistant that uses a tool from the `tools/my_tool.rb` file. In the `start` file, you will find the algorithm for applying this assistant.

3. Modify the code as needed and run:

    ```sh
    .oxaiworkers-local/start
    ```

## Logging

OxAiWorkers uses standard logging mechanisms and defaults to `:warn` level. Most messages are at info level, but we will add debug or warn statements as needed.
To show all log messages:

```ruby
OxAiWorkers.logger.level = :debug
```

## Real World Examples

### Project: Python Snake Game

1. Create the project folder:

    ```sh
    mkdir snake
    cd snake
    ```

2. Initialize OxAiWorkers:

    ```sh
    oxaiworkers init
    ```

3. Modify the file `.oxaiworkers-local/start`:

    ```ruby
    # Replace
    @assistant = OxAiWorkers::Assistant::Sysop.new

    # With
    @assistant = OxAiWorkers::Assistant::Coder.new(language: 'python')
    ```

4. Run the project:

    ```sh
    .oxaiworkers-local/start
    ```

5. In the command prompt, type:

    ```sh
    @assistant.task = "Write a snake game"
    ```

### Running System Operator in Any Directory

To run OxAiWorkers in any directory, execute the following command:

```sh
oxaiworkers run sysop
```

Alternatively, you can use IRB (Interactive Ruby):

1. Start IRB:

    ```sh
    irb
    ```

2. In the console, enter the following commands (see Usage section):

    ```ruby
    require 'ox-ai-workers'
    @sysop = OxAiWorkers::Assistant::Sysop.new
    ```

Then set a task:

```ruby
@sysop.task = "Show all cron jobs"
```

After these steps you can interact with it using the following method:

```ruby
@sysop.add_response("Yes, I want it")
```

or set a new task.

## Features

- **Generative Intelligence**: Leverages OpenAI's capabilities to enhance task execution.
- **Internal Monologue**: Uses inner monologue to plan responses and articulate main points.
- **External Tools**: Integrates with external tools and services to complete tasks.
- **Finite State Machine**: Implements a robust state machine to manage task states and transitions.
- **Multilingual Support**: Complete I18n integration with ready-to-use English and Russian locales.
- **Token Optimization**: Automatic management of context through summarization to optimize token usage.
- **Streaming Responses**: Support for streaming responses with callback processing for real-time interaction.
- **Error Recovery**: Automatic retries and error handling mechanisms for reliable operation.
- **Custom Tool Development**: Flexible framework for creating domain-specific tools and assistants.

## Advanced Usage Patterns

### Creating Custom Tools

You can create custom tools by extending the `ToolDefinition` module:

```ruby
class MyTool
  include OxAiWorkers::ToolDefinition
  
  def initialize
    define_function :hello_world, description: "Says hello to someone" do
      property :name, type: "string", description: "Name to greet", required: true
    end
  end
  
  def hello_world(name:)
    "Hello, #{name}!"
  end
end
```

### Handling State Transitions with Callbacks

You can track and respond to state transitions with callbacks:

```ruby
iterator = OxAiWorkers::Iterator.new(
  worker: worker,
  tools: [my_tool],
  on_inner_monologue: ->(text:) { save_to_database(text) },
  on_outer_voice: ->(text:) { notify_user(text) },
  on_action_request: ->(text:) { log_request(text) },
  on_summarize: ->(text:) { optimize_dialog_history(text) },
  on_finish: -> { mark_task_completed }
)
```

### Optimizing Context with Milestones

For long-running tasks, you can use the summarize function to compress dialog history:

```ruby
# In your tool's implementation
def complete_complex_task(params:)
  # ... processing logic ...
  result = "Complex task completed: #{intermediate_result}"
  
  # Suggest to the LLM to summarize the conversation
  # This will be picked up by the Iterator and processed
  "Task phase completed. Consider using summarize to compress our dialog history before continuing with the next phase. #{result}"
end
```

### Streaming API Responses

Enable streaming for real-time feedback:

```ruby
worker = OxAiWorkers::Request.new(
  on_stream: ->(chunk) { 
    if chunk.dig('choices', 0, 'delta', 'content')
      print chunk.dig('choices', 0, 'delta', 'content') 
    end
  }
)
```

### Available Assistant Types

OxAiWorkers provides several specialized assistant types:

- **Sysop**: System administration and shell command execution

  ```ruby
  sysop = OxAiWorkers::Assistant::Sysop.new
  sysop.task = "Configure nginx for my Rails application"
  ```

- **Coder**: Code generation and analysis with language-specific configuration

  ```ruby
  coder = OxAiWorkers::Assistant::Coder.new(language: 'ruby')
  coder.task = "Create a Sinatra API with three endpoints"
  ```

- **Localizer**: Translation and localization support

  ```ruby
  localizer = OxAiWorkers::Assistant::Localizer.new(source_lang: 'en', target_lang: 'ru')
  localizer.task = "Translate my application's interface"
  ```

### Implementing Your Own Assistant

Create custom assistants by inheriting from existing ones or composing with the Iterator:

```ruby
module OxAiWorkers
  module Assistant
    class DataAnalyst
      include OxAiWorkers::Assistant::ModuleBase
      
      def initialize(delayed: false, model: nil)
        store_locale
        @iterator = Iterator.new(
          worker: init_worker(delayed: delayed, model: model),
          role: "You are a data analysis assistant specialized in processing CSV and JSON data",
          tools: [Tool::FileSystem.new, Tool::Eval.new(only: [:ruby])],
          locale: @locale
        )
      end
    end
  end
end
```

### Using the Workspace for Multi-Agent Collaboration

OxAiWorkers provides a Workspace class to organize multiple assistants and facilitate their collaboration:

```ruby
# Create a workspace
workspace = OxAiWorkers::Workspace.new(
  title: "Software Development Team",
  description: "A team of AI assistants working on software development tasks"
)

# Add different assistants to the workspace
workspace.add_assistant("architect", OxAiWorkers::Assistant::Coder.new(
  title: "Software Architect",
  description: "Designs system architecture and makes key technical decisions",
  capabilities: ["system design", "API design", "technology selection", "code review", "architecture optimization"],
  role: "You are an experienced software architect responsible for designing robust, scalable systems. Your expertise lies in creating clean APIs and selecting appropriate technologies for projects."
))

workspace.add_assistant("developer", OxAiWorkers::Assistant::Coder.new(
  title: "Developer",
  description: "Implements code according to specifications",
  capabilities: ["code development", "debugging", "refactoring", "API integration", "database work"], 
  role: "You are a skilled Ruby developer with experience in web application development. Your job is to implement code according to specifications while maintaining clean, maintainable code."
))

workspace.add_assistant("tester", OxAiWorkers::Assistant::Coder.new(
  title: "QA Engineer",
  description: "Tests software and ensures quality",
  capabilities: ["test writing", "test automation", "bug detection", "security testing", "load testing"],
  role: "You are a quality assurance engineer focused on ensuring software reliability and security. You specialize in automated testing and finding edge cases that might cause problems."
))

# Define a workflow for the team
workflow_description = <<~WORKFLOW
  Create a REST API for a blog with posts and comments.
  
  The process should include:
  1. Designing the system architecture (models, controllers, routes)
  2. Implementing code according to the architecture
  3. Writing tests to verify API functionality
  4. Checking overall code quality and security
  
  The architect should design the system, using their API design capabilities.
  The developer should implement the code, using their Ruby and database skills.
  The tester should write tests and verify code quality, using their test automation and bug detection skills.
WORKFLOW

workspace.set_workflow(workflow_description)

# Execute the workflow
result = workspace.execute_next_step
while result[:status] == 'pending'
  puts "Assigned task to: #{result[:assistant_id]}"
  puts "Task: #{result[:task]}"
  
  # Get the result from the assistant
  assistant = workspace.get_assistant(result[:assistant_id])
  
  # Get information about the assistant's capabilities for this task
  capabilities = assistant.capabilities
  puts "Using capabilities: #{capabilities.join(', ')}"
  
  # ... interact with the assistant if needed
  
  # Get the result from the assistant
  assistant.execute
  
  # Pass the assistant's response back to the workflow
  assistant_response = {
    assistant_id: result[:assistant_id],
    message: assistant.iterator.result
  }
  
  puts "Task completed by assistant: #{result[:assistant_id]}"
  
  # Move to the next step
  result = workspace.execute_next_step(assistant_response)
end

puts "Workflow completed: #{result[:message]}"

The Workspace provides the following key features:

- **Multi-agent coordination**: Manages multiple assistants with different specializations
- **Task orchestration**: Uses an orchestrator to plan and assign tasks based on assistant capabilities
- **Message passing**: Enables assistants to exchange information
- **Workflow execution**: Manages the state and progression of complex workflows
- **Message history**: Keeps track of all communication between assistants

### Task Distribution Based on Capabilities

The orchestrator in the workspace makes decisions about task assignments based on assistant capabilities. For example:

```ruby
# Example of how the orchestrator can analyze capabilities
def assign_task(task, available_assistants)
  case task[:type]
  when "architecture"
    # Look for an assistant with architecture design capabilities
    architect = available_assistants.find { |id, assistant| 
      assistant.capabilities.any? { |cap| cap.include?("design") } 
    }
    return architect&.first
  when "development"
    # Look for an assistant with development skills
    developer = available_assistants.find { |id, assistant| 
      assistant.capabilities.any? { |cap| cap.include?("development") } 
    }
    return developer&.first
  when "testing"
    # Look for an assistant with testing skills
    tester = available_assistants.find { |id, assistant| 
      assistant.capabilities.any? { |cap| cap.include?("test") } 
    }
    return tester&.first
  end
end
```

When defining the workflow, you can specify the required capabilities that the orchestrator will consider when assigning tasks:

```ruby
workflow_description = <<~WORKFLOW
  Creating an authentication microservice:
  
  1. Design an authentication API (requires: API design)
  2. Implement JWT authentication (requires: code development, database work)
  3. Write tests for all endpoints (requires: test automation)
  4. Check security (requires: security verification)
WORKFLOW
```

## Contributing
