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
I18n.load_path += Dir[File.expand_path("locales") + "/*.yml"] # for pure Ruby
I18n.default_locale = :en # for pure Ruby
require 'ox-ai-workers'

# Initialize the assistant
sysop = OxAiWorkers::Assistant::Sysop.new()

# Add a task
sysop.addTask("Add a cron job to synchronize files daily.")
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
        steps:
          - "Step 1: Develop your own solution to the problem. Take initiative and make assumptions."
          - "Step 1.1: Wrap all your work for this step in the innerMonologue function."
          - "Step 2: Relate your solution to the task, improve it, and call the necessary functions step by step."
          - "Step 2.1: Interact with the user using the outerVoice and actionRequest functions during the process."
          - "Step 3: When the solution is ready, report it using the outerVoice function."
          - "Step 3.1: Save facts, nuances, and actions using the packHistory function."
          - "Step 4: Conclude the work with the actionRequest function, without repeating the response if it was already given with outerVoice."
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