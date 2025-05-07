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
sysop.add_task("blah-blah-blah")
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
iterator.task = "Show files in current dir"
iterator.execute

# Provide a response to the gpt's question
iterator.task = "linux"
iterator.execute
```

### With Config

For a more robust setup, you can configure the gem with your API keys, for example in an oxaiworkers.rb initializer file. Never hardcode secrets into your codebase - instead use something like [dotenv](https://github.com/motdotla/dotenv) to pass the keys safely into your environments.

```ruby
OxAiWorkers.configure do |config|
    config.access_token_openai = ENV.fetch("OPENAI")
    config.access_token_deepseek = ENV.fetch("DEEPSEEK")
    config.max_tokens = 4096   # Default
    config.temperature = 0.7   # Default
    config.wait_for_complete = true # Default
end

# Set the default model
OxAiWorkers.default_model = OxAiWorkers::Models::OpenaiMini.new
```

Then you can create an assistant like this:

```ruby
assistant = OxAiWorkers::Assistant::Sysop.new()
assistant.task = "Remove all cron jobs."
assistant.execute

# Provide a response to the assistant's question
assistant.add_task("blah-blah-blah")
assistant.execute
```

Besides, you can create assistants with different locales

```ruby
I18n.with_locale(:en) { @sysop_en = OxAiWorkers::Assistant::Sysop.new() }

# Assign tasks and responses in different languages
@sysop_en.run_task "Remove all cron jobs."
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
    on_finish: -> { puts "finish".colorize(:magenta) }
  )

iterator.task = "Show files in current directory."
iterator.execute
# ...
iterator.add_task "linux"
iterator.execute
```

This way, you have the flexibility to choose between a higher-level assistant for simplicity or a lower-level iterator for finer control over the tasks and tools used.

### Advanced instructions for your Assistant

```ruby
steps = []
steps << 'Step 1. Develop your own solution to the problem, taking initiative and making assumptions.'
steps << "Step 2. Enclose all your developments from the previous step in the #{OxAiWorkers::Iterator.full_function_name(:inner_monologue)} function."
steps << 'Step 3. Call the necessary functions one after another until the desired result is achieved.'
steps << "Step 4. When the solution is ready, notify about it and wait for the user's response."

# To retain the locale if you have assistants in different languages in your project.
store_locale # Optional

@iterator = OxAiWorkers::Iterator.new(
  worker: init_worker(delayed: delayed, model: model),
  role: 'You are a software agent inside my computer',
  tools: [MyTool.new],
  locale: @locale || I18n.locale,
  steps: steps,
  # def_except: [:outer_voice], # It's except steps with that functions
  # def_only: [:inner_monologue, :outer_voice], # Use it only with your steps
  on_inner_monologue: ->(text:) { puts "monologue: #{text}".colorize(:yellow) },
  on_outer_voice: ->(text:) { puts "voice: #{text}".colorize(:green) }
)
```

### Worker Options

As a worker, you can use different classes depending on your needs:

- `OxAiWorkers::Request`: This class is used for immediate request execution. It is suitable for operations that require instant responses.

- `OxAiWorkers::DelayedRequest`: This class is used for batch API requests, ideal for operations that do not require immediate execution. Using `DelayedRequest` can save up to 50% on costs as requests are executed when the remote server is less busy, but no later than within 24 hours.

### Alternative Models

OxAiWorkers supports alternative compatible models like DeepSeek. To use these models, specify the appropriate base URI in the initializer:

```ruby
# Use the closest available model and override its parameters
model = OxAiWorkers::Models::OpenaiMini.new(
    uri_base: "https://api.deepseek.com/",
    api_key: ENV.fetch("DEEPSEEK"),
    model: "deepseek-chat"
)

worker = OxAiWorkers::Request.new(
    model: model,
)
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
    @assistant.run_task("Write a snake game")
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
@sysop.run_task "Show all cron jobs"
```

After these steps you can interact with it using the following method:

```ruby
@sysop.run_task "Yes, I want it All"
```

or set a new task.

## Features

- **Generative Intelligence**: Leverages OpenAI's capabilities to enhance task execution.
- **Internal Monologue**: Uses inner monologue to plan responses and articulate main points.
- **External Tools**: Integrates with external tools and services to complete tasks.
- **Finite State Machine**: Implements a robust state machine to manage task states and transitions.
- **Multilingual Support**: Complete I18n integration with ready-to-use English and Russian locales.
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
  on_finish: -> { mark_task_completed }
)
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

- **Painter**: Image generation and manipulation

  ```ruby
  painter = OxAiWorkers::Assistant::Painter.new
  # or Set working directory to save generated images as files
  # painter = OxAiWorkers::Assistant::Painter.new(current_dir: Dir.pwd)
  painter.task = "Create an image of a sunset over mountains"
  ```

- **Orchestrator**: Coordinates multiple assistants to work together on complex tasks

  ```ruby
  orchestrator = OxAiWorkers::Assistant::Orchestrator.new(
    workflow: 'Development team creates an application and tests it.'
  )
  orchestrator.add_assistant(OxAiWorkers::Assistant::Coder.new)
  orchestrator.add_assistant(OxAiWorkers::Assistant::Sysop.new)
  orchestrator.add_assistant(OxAiWorkers::Assistant::Localizer.new)
  orchestrator.task = "Create a hello world application in C, save it to hello_world.c, compile, run, and verify it works."
  ```

### Available Tools

OxAiWorkers provides several specialized tools to extend functionality:

- **Pixels**: Image generation and manipulation tool

  ```ruby
  # Initialize with worker and optional parameters
  pixels = OxAiWorkers::Tool::Pixels.new(
    worker: worker,                 # Required: Request or DelayedRequest instance
    current_dir: Dir.pwd,           # Optional: Directory to save generated images
    image_model: 'dall-e-3',        # Optional: 'dall-e-3' or 'gpt-image-1'
    only: [:generate_image]         # Optional: Limit available functions
  )
  ```

  Provides functions for generating images with customizable parameters like size and quality, with ability to save generated images to disk.

- **Pipeline**: Assistant coordination and communication tool

  ```ruby
  # Initialize with optional parameters
  pipeline = OxAiWorkers::Tool::Pipeline.new(
    on_message: ->(text:) { puts text } # Optional: Message handler callback
  )
  
  # Add assistants to the pipeline
  pipeline.add_assistant(OxAiWorkers::Assistant::Coder.new)
  pipeline.add_assistant(OxAiWorkers::Assistant::Sysop.new)
  ```

  Enables communication between multiple assistants, maintaining message context and facilitating collaborative problem-solving.

- **Eval**: Code execution tool

  ```ruby
  # Initialize with optional parameters
  eval_tool = OxAiWorkers::Tool::Eval.new(
    only: [:ruby, :sh],             # Optional: Limit available functions
    current_dir: Dir.pwd            # Optional: Directory to execute commands in
  )
  ```

  Allows execution of Ruby code and shell commands, with directory context support.

- **FileSystem**: File operations tool

  ```ruby
  # Initialize with optional parameters
  file_system = OxAiWorkers::Tool::FileSystem.new(
    current_dir: Dir.pwd,           # Optional: Base directory for operations
    only: [:list_directory, :read_file, :write_to_file] # Optional: Limit available functions
  )
  ```

  Provides functions for listing directory contents, reading from files, and writing to files with support for relative paths.

Additional tools like Database and Converter are available for specialized tasks and can be integrated using the same pattern.

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

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/neonix20b/ox-ai-workers>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/neonix20b/ox-ai-workers/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the OxAiWorkers project's codebases, issue trackers, chat rooms, and mailing lists is expected to follow the [code of conduct](https://github.com/neonix20b/ox-ai-workers/blob/main/CODE_OF_CONDUCT.md).
