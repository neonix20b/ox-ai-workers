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
I18n.load_path += Dir[File.expand_path("locales") + "/*.yml"] # only for pure Ruby
I18n.default_locale = :en # only for pure Ruby

# Require the main gem
require 'ox-ai-workers'

# Initialize the assistant
sysop = OxAiWorkers::Assistant::Sysop.new(delayed: false, model: "gpt-4o")

# Add a task to the assistant
sysop.setTask("Add a cron job to synchronize files daily.")

# Provide a response to the assistant's question
sysop.addResponse("blah-blah-blah")
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
iterator.addTask("Show files in current dir")

# Provide a response to the gpt's question
iterator.addTask("linux")
```

### With Config

For a more robust setup, you can configure the gem with your API keys, for example in an oxaiworkers.rb initializer file. Never hardcode secrets into your codebase - instead use something like [dotenv](https://github.com/motdotla/dotenv) to pass the keys safely into your environments.

```ruby
OxAiWorkers.configure do |config|
    config.access_token = ENV.fetch("OPENAI")
    config.model = "gpt-4o"
    config.max_tokens = 4096
    config.temperature = 0.7
end
```

Then you can create an assistant like this:

```ruby
assistant = OxAiWorkers::Assistant::Sysop.new()
assistant.setTask("your task")

# Provide a response to the assistant's question
assistant.addResponse("blah-blah-blah")
```

Or you can create a lower-level iterator for more control:

```ruby
iterator = OxAiWorkers::Iterator.new(
  worker: OxAiWorkers::Request.new, 
  tools: [OxAiWorkers::Tool::Eval.new],
  role: "You are a software agent inside my computer" )

iterator.addTask("Show files in current directory.")
# ...
iterator.addTask("linux")
```

This way, you have the flexibility to choose between a higher-level assistant for simplicity or a lower-level iterator for finer control over the tasks and tools used.

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

This will create a `.oxaiworkers-local` directory with the necessary initial settings. 

Additionally, you can initialize a more comprehensive example using the command:

```sh
oxaiworkers init full
```

After this, in the `my_assistant.rb` file, you can find an example of an assistant that uses a tool from the `tools/my_tool.rb` file. In the `start` file, you will find the algorithm for applying this assistant.

3. Modify the code as needed and run:

```sh
.oxaiworkers-local/start
```

## Features

- **Generative Intelligence**: Leverages OpenAI's capabilities to enhance task execution.
- **Internal Monologue**: Uses inner monologue to plan responses and articulate main points.
- **External Tools**: Integrates with external tools and services to complete tasks.
- **Finite State Machine**: Implements a robust state machine to manage task states and transitions.

## Configuration

OxAiWorkers uses YAML files for configuration. Below is an example configuration:

```yaml
en:
  oxaiworkers:
    iterator:
      inner_monologue:
        description: "Use inner monologue to plan the response and articulate main points"
        speech: "Text"
      outer_voice:
        description: "Provide the user with necessary information without expecting a response"
        text: "Text"
      action_request:
        description: "Ask a clarifying question or request an action with a response from the user"
        action: "Text"
      pack_history:
        description: "Save facts, nuances, and actions before clearing messages"
        text: "Listing important facts and nuances"
      monologue:
        - "Step 1: Develop your own solution to the problem. Take initiative and make assumptions."
        - "Step 1.1: Wrap all your work for this step in the innerMonologue function."
        - "Step 2: Relate your solution to the task, improve it, and call the necessary functions step by step."
        - "Step 2.1: Interact with the user using the outerVoice and actionRequest functions during the process."
        - "Step 3: When the solution is ready, report it using the outerVoice function."
        - "Step 4: Save facts, nuances, and actions using the packHistory function."
    tool:
      eval:
        ruby:
          description: "Execute Ruby code and return the result of the last expression"
          input: "Ruby source code"
        sh:
          description: "Execute a sh command and get the result (stdout + stderr)"
          input: "Source command"
    assistant:
      sysop:
        role: "You are a software agent inside my computer"
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/neonix20b/ox-ai-workers. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/neonix20b/ox-ai-workers/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the OxAiWorkers project's codebases, issue trackers, chat rooms, and mailing lists is expected to follow the [code of conduct](https://github.com/neonix20b/ox-ai-workers/blob/main/CODE_OF_CONDUCT.md).