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
    config.access_token_stability = ENV.fetch("STABILITY")
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

tool = MyTool.new

@iterator = OxAiWorkers::Iterator.new(
  worker: init_worker(delayed: delayed, model: model),
  role: 'You are a software agent inside my computer',
  tools: [tool],
  locale: @locale || I18n.locale,
  steps: steps,
  # def_except: [:outer_voice], # It's except steps with that functions
  # def_only: [:inner_monologue, :outer_voice], # Use it only with your steps
  # Forced Function: Uses call_stack parameter to force the model to call functions in this exact order, one at a time
  # call_stack: [ 
  #   OxAiWorkers::Iterator.full_function_name(:outer_voice),
  #   tool.full_function_name(:func1)
  # ],
  # Stop Double Calls: Uses stop_double_calls parameter to prevent the model from calling the same function twice in a row
  # stop_double_calls: [
  #   tool.full_function_name(:func1)
  # ],
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
  
  attr_accessor :messages
  
  def initialize
    @messages = []
    
    define_function :hello_world, description: "Says hello to someone" do
      property :name, type: "string", description: "Name to greet" # Default required: true
      property :age, type: ["integer", "null"], description: "Age of the person" # Default required: true, can be null so it's optional
    end
  end
  
  def hello_world(name:)
    @messages << "Greeted #{name}"
    "Hello, #{name}!"
  end
  
  # The context method provides information to assistants using this tool before each request
  def context
    return nil if @messages.empty?
    "Tool activity log:\n#{@messages.join("\n")}"
  end
end
```

The `define_function` method accepts an optional `strict` parameter (defaults to `true`) that controls whether additional properties are allowed in the input. When `strict: true` (default), the schema will include `additionalProperties: false`, enforcing that only defined properties can be used. Tools can also implement a `context` method that returns information to be included in assistant conversations before each request, which is particularly useful when multiple assistants share a common tool to maintain shared state or history.

### Working with Files and Images

You can easily add files and images to your assistants:

```ruby
# Add a PDF file
iterator.add_file(
  pdf: File.read('document.pdf'),
  filename: 'document.pdf',
  text: 'Here is the document you requested'
)

# Add image from URL
iterator.add_image(
  text: 'Here is the image',
  url: 'https://example.com/image.jpg',
  detail: 'auto' # 'auto', 'low', or 'high'
)

# Add image from binary data
image_data = File.read('local_image.jpg')
iterator.add_image(
  text: 'Image from binary data',
  binary: image_data,
  mime_type: 'image/jpeg' # Defaults to 'image/png'
)
```

#### Image Input Requirements

When using images with the API, your input images must meet the following requirements:

**Supported file types:**

- PNG (.png)
- JPEG (.jpeg and .jpg)
- WEBP (.webp)
- Non-animated GIF (.gif)

**Size limits:**

- Up to 20MB per image
- Low-resolution: 512px x 512px
- High-resolution: 768px (short side) x 2000px (long side)

**Other requirements:**

- No watermarks or logos
- No text
- No NSFW content
- Clear enough for a human to understand

**Image detail level:**

The `detail` parameter controls what level of detail the model uses when processing the image:

```ruby
iterator.add_image(
  text: 'Nature boardwalk image',
  url: 'https://example.com/nature.jpg',
  detail: 'high' # Options: 'auto', 'low', or 'high'
)
```

- `detail: 'low'`: Uses less tokens (85) and processes a low-resolution 512px x 512px version of the image. Best for simple use cases like identifying dominant colors or shapes.
- `detail: 'high'`: Provides better image understanding for complex tasks requiring higher resolution detail.
- `detail: 'auto'`: Lets the model decide the appropriate detail level (default if not specified).

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

- **Expert**: Mathematical and scientific problem solving using Wolfram Alpha

  ```ruby
  expert = OxAiWorkers::Assistant::Expert.new
  # or with optional location parameter for location-aware queries
  # expert = OxAiWorkers::Assistant::Expert.new(location: 'Berlin')
  expert.task = "Calculate the derivative of x^3 + 5x^2 + 2x + 1"
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

All assistants support working with files and images:

```ruby
# Add files and images to any assistant
sysop.add_file(pdf: File.read('error_log.pdf'), filename: 'error_log.pdf', text: 'Error log file')
sysop.add_image(text: 'Screenshot of the error', url: 'https://example.com/screenshot.png')
```

See the [Working with Files and Images](#working-with-files-and-images) section for full details.

### Available Tools

OxAiWorkers provides several specialized tools to extend functionality:

- **Pixels**: Image generation and manipulation tool

  ```ruby
  # Initialize with worker and optional parameters
  pixels = OxAiWorkers::Tool::Pixels.new(
    worker: worker,                 # Required: Request or DelayedRequest instance
    current_dir: Dir.pwd,           # Optional: Directory to save generated images
    image_model: OxAiWorkers::Models::StabilityImages.new,       # Optional, default is OpenaiDalle3
    only: [:generate_image]         # Optional: Limit available functions
  )
  ```

  Provides functions for generating images with customizable parameters like size and quality, with ability to save generated images to disk.

- **Wolfram**: Query the Wolfram Alpha computational knowledge engine

  ```ruby
  `gem "wolfram-alpha", github: "neonix20b/wolfram-alpha"`
  ```

  ```ruby
  OxAiWorkers.configuration.access_token_wolfram = 'YOUR_WOLFRAM_API_KEY'
  ```

  ```ruby
  # Initialize with optional parameters
  wolfram = OxAiWorkers::Tool::Wolfram.new(
    access_token: 'YOUR_WOLFRAM_API_KEY', # Optional: API key
    location: 'Berlin' # Optional: Location to use for the query
  )
  ```

  This tool enables access to Wolfram Alpha's vast computational intelligence for performing complex mathematical calculations, solving equations, accessing scientific data, and answering knowledge-based queries with precise, authoritative results.

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
  gem "ptools"
  ```

  ```ruby
  # Initialize with optional parameters
  file_system = OxAiWorkers::Tool::FileSystem.new(
    current_dir: Dir.pwd,           # Optional: Base directory for operations
    only: [:list_directory, :read_file, :write_to_file] # Optional: Limit available functions
  )
  ```

  Provides functions for listing directory contents, reading from files, and writing to files with support for relative paths.

Additional tools like Database and Converter are available for specialized tasks and can be integrated using the same pattern.

### Function Control Mechanisms

OxAiWorkers provides two powerful mechanisms to control function execution behavior in iterators:

#### Call Stack

The `call_stack` parameter allows you to force the model to call specific functions in a predetermined order:

```ruby
iterator = OxAiWorkers::Iterator.new(
  worker: worker,
  tools: [my_tool],
  call_stack: [
    my_tool.full_function_name(:process_data),
    OxAiWorkers::Iterator.full_function_name(:outer_voice),
  ]
)
```

This feature is particularly useful when:

- You need to ensure a specific sequence of operations
- Certain functions must be called before others
- You want to guide the model through a predefined workflow
- Complex operations require strict ordering of function calls

The `call_stack` is processed sequentially, with each function being removed from the stack after it's called.

#### Stop Double Calls

The `stop_double_calls` parameter prevents the model from calling the same function twice in consecutive operations:

```ruby
iterator = OxAiWorkers::Iterator.new(
  worker: worker,
  tools: [my_tool],
  stop_double_calls: [
    my_tool.full_function_name(:expensive_operation)
  ]
)
```

This feature is valuable for:

- Preventing redundant operations that could waste resources
- Avoiding duplicate processing of the same data
- Ensuring that certain operations are executed only once in sequence
- Protecting against potential infinite loops in function calls

When a function is called, its name is stored as the `last_call`. If the next function call matches both the `last_call` and is included in the `stop_double_calls` list, it will be excluded from the available tools for that request.

By default, `stop_double_calls` is applied to the `inner_monologue` and `outer_voice` functions to prevent reasoning loops and repetitive responses. This default behavior helps models avoid getting stuck in circular thinking patterns.

If you need to override this default behavior (for example, when consecutive monologue or voice calls are required for your specific use case), you can reset the stop_double_calls list **after** the iterator is created:

```ruby
# Clear the default stop_double_calls constraints
@iterator.stop_double_calls = []

# Or set your own custom constraints
@iterator.stop_double_calls = [my_tool.full_function_name(:specific_function)]
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

## Image Generation

OxAiWorkers supports image generation through the Painter assistant and Pixels tool, with multiple AI image generation models.

### Supported Image Models

- **OpenaiDalle3** - OpenAI's DALL-E 3 model
- **OpenaiGptImage** - OpenAI's GPT-Image-1 model
- **StabilityImages** - Stability AI's image generation models

### Using the Painter Assistant

```ruby
# Using DALL-E 3 (default)
painter = OxAiWorkers::Assistant::Painter.new(current_dir: Dir.pwd)
painter.task = "Create an image of a sunset over mountains"

# Using GPT-Image-1
painter = OxAiWorkers::Assistant::Painter.new(
  image_model: OxAiWorkers::Models::OpenaiGptImage.new,
  current_dir: Dir.pwd
)
painter.task = "Generate a photorealistic red apple"

# Using Stability AI
painter = OxAiWorkers::Assistant::Painter.new(
  image_model: OxAiWorkers::Models::StabilityImages.new,
  current_dir: Dir.pwd
)
painter.task = "Create a fantasy landscape with dragons"
```

### Using the Pixels Tool Directly

For more direct control over image generation:

```ruby
# Initialize with DALL-E 3
pixels = OxAiWorkers::Tool::Pixels.new(
  worker: OxAiWorkers::Models::OpenaiDalle3.new,
  current_dir: Dir.pwd
)
pixels.generate_image(
  prompt: "A photorealistic red apple on a wooden table",
  file_name: "apple.png",
  size: "1024x1024",
  quality: "hd"
)

# Initialize with GPT-Image-1
pixels = OxAiWorkers::Tool::Pixels.new(
  worker: OxAiWorkers::Models::OpenaiGptImage.new,
  current_dir: Dir.pwd
)
pixels.generate_image(
  prompt: "Futuristic cityscape at night",
  file_name: "city.png",
  size: "1536x1024",
  quality: "high"
)

# Initialize with Stability AI
pixels = OxAiWorkers::Tool::Pixels.new(
  worker: OxAiWorkers::Models::StabilityImages.new,
  current_dir: Dir.pwd
)
pixels.generate_image(
  prompt: "Photorealistic mountain landscape",
  file_name: "mountains.png"
)
```

### Model-Specific Features

- **OpenaiDalle3**
  - Sizes: '1024x1024', '1024x1792', '1792x1024'
  - Qualities: 'standard', 'hd'

- **OpenaiGptImage**
  - Sizes: 'auto', '1024x1024', '1536x1024', '1024x1536'
  - Qualities: 'auto', 'low', 'medium', 'high'

- **StabilityImages**
  - Uses Stability AI's API with different engine options
  - Configuration via options parameter

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/neonix20b/ox-ai-workers>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/neonix20b/ox-ai-workers/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the OxAiWorkers project's codebases, issue trackers, chat rooms, and mailing lists is expected to follow the [code of conduct](https://github.com/neonix20b/ox-ai-workers/blob/main/CODE_OF_CONDUCT.md).
