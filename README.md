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
    on_summarize: ->(text:) { puts "summary: #{text}".colorize(:blue) }
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

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/neonix20b/ox-ai-workers>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/neonix20b/ox-ai-workers/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the OxAiWorkers project's codebases, issue trackers, chat rooms, and mailing lists is expected to follow the [code of conduct](https://github.com/neonix20b/ox-ai-workers/blob/main/CODE_OF_CONDUCT.md).
