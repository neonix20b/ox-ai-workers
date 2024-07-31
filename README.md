[![Gem Version](https://badge.fury.io/rb/ox-ai-workers.svg)](https://rubygems.org/gems/ox-ai-workers)

# OxAiWorkers (ox-ai-workers)

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
my_tool = OxAiWorkers::Tool::Eval.new()

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
    config.max_tokens = 4096
    config.temperature = 0.7
    config.auto_execute = true
end
```

Then you can create an assistant like this:

```ruby
assistant = OxAiWorkers::Assistant::Sysop.new()
assistant.task = "your task"

# Provide a response to the assistant's question
assistant.add_response("blah-blah-blah")
```

Or you can create a lower-level iterator for more control:

```ruby
my_worker = OxAiWorkers::Request.new
my_tool = OxAiWorkers::Tool::Eval.new

iterator = OxAiWorkers::Iterator.new(
    worker: my_worker, 
    tools: [my_tool],
    role: "You are a software agent inside my computer",
    on_inner_monologue: ->(text:) { puts "monologue: #{text}".colorize(:yellow) },
    on_outer_voice: ->(text:) { puts "voice: #{text}".colorize(:green) },
    on_action_request: ->(text:) { puts "action: #{text}".colorize(:red) },
    on_pack_history: ->(text:) { puts "summary: #{text}".colorize(:blue) }
  )

iterator.add_task("Show files in current directory.")
# ...
iterator.add_task("linux")
```

This way, you have the flexibility to choose between a higher-level assistant for simplicity or a lower-level iterator for finer control over the tasks and tools used.

### Advanced instructions for your Assistant

```ruby
steps = []
steps << 'Step 1. Develop your own solution to the problem, taking initiative and making assumptions.'
steps << 'Step 2. Enclose all your developments from the previous step in the ox_ai_workers_iterator__inner_monologue function.'
steps << 'Step 3. Call the necessary functions one after another until the desired result is achieved.'
steps << 'Step 4. When all intermediate steps are completed and the exact content of previous messages is no longer relevant, use the ox_ai_workers_iterator__pack_history function.'
steps << "Step 5. When the solution is ready, notify about it and wait for the user's response."

@iterator = OxAiWorkers::Iterator.new(
  worker: init_worker(delayed: delayed, model: model),
  role: 'You are a software agent inside my computer',
  tools: [MyTool.new],
  steps: steps,
  on_inner_monologue: ->(text:) { puts "monologue: #{text}".colorize(:yellow) },
  on_outer_voice: ->(text:) { puts "voice: #{text}".colorize(:green) },
  on_action_request: ->(text:) { puts "action: #{text}".colorize(:red) },
  on_pack_history: ->(text:) { puts "summary: #{text}".colorize(:blue) }
)
```

### Worker Options

As a worker, you can use different classes depending on your needs:

- `OxAiWorkers::Request`: This class is used for immediate request execution. It is suitable for operations that require instant responses.

- `OxAiWorkers::DelayedRequest`: This class is used for batch API requests, ideal for operations that do not require immediate execution. Using `DelayedRequest` can save up to 50% on costs as requests are executed when the remote server is less busy, but no later than within 24 hours.

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

## Features

- **Generative Intelligence**: Leverages OpenAI's capabilities to enhance task execution.
- **Internal Monologue**: Uses inner monologue to plan responses and articulate main points.
- **External Tools**: Integrates with external tools and services to complete tasks.
- **Finite State Machine**: Implements a robust state machine to manage task states and transitions.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/neonix20b/ox-ai-workers. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/neonix20b/ox-ai-workers/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the OxAiWorkers project's codebases, issue trackers, chat rooms, and mailing lists is expected to follow the [code of conduct](https://github.com/neonix20b/ox-ai-workers/blob/main/CODE_OF_CONDUCT.md).