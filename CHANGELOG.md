## [1.0.2] - 2025-05-17

- Added `openai_whisper` model
- Added `openai_transcribe` model
- Added `tool_call_id` for `Iterator`

## [1.0.1] - 2025-05-13

- Property `required` parameter is now `true` by default in `define_function`
- Fixed `type` parameter for `define_function`

## [1.0.0] - 2025-05-12

- Final version for 1.0.0 release

## [0.9.9] - 2025-05-12

- Added `strict` parameter for `define_function`
- Added `Wolfram` tool
- Added `Expert` assistant

## [0.9.6] - 2025-05-10

- Added `add_file` for `Iterator` (only pdf for now)
- Added `add_image` for `Iterator`
- Added `add_file` and `add_image` for Assistants
- Added `call_stack` for `Iterator` and `ModuleRequest`
- Added `stop_double_calls` for `Iterator` and `ModuleRequest`

## [0.9.4] - 2025-05-08

- Added `stability_images` model
- Added `openai_gpt_image` model
- Added `openai_dalle3` model
- Added `access_token_stability` for configuration

## [0.9.3] - 2025-05-06

- Changed `max_tokens` to `max_completion_tokens` in `params`
- Added `frequency_penalty` for configuration
- Added `edit_image` for `Pixels` tool

## [0.9.1] - 2025-05-04

- Added `current_dir` for `Eval`, `FileSystem`, `Pixels` tools
- Added `current_dir` for `Coder`, `Localizer`, `Painter`, `Sysop` assistants
- Added `run_task` for Assistants

## [0.9.0] - 2025-05-03

- Added `context` for tools in `Iterator`
- Added `Pipeline` tool
- Added `Pixels` tool
- Added `Painter` assistant
- Added `Orchestrator` assistant
- Added collaboration between assistants
- Added classes for AI models: `OpenaiMini`, `OpenaiNano`, `OpenaiMax`, `DeepseekMax`
- Added `default_model` for configuration
- Removed `action_request` and `summarize` from `Iterator`
- Removed `auto_execute` from `Iterator`
- Renamed `add_response` to `add_task` in `Assistant`

## [0.8.7] - 2025-04-25

- Fixed tool calls parsing
- Refine Russian locale for Iterator with enhanced step descriptions and planning guidance
- Update locale for Iterator
- Added `on_stream` for `Iterator`

## [0.7.10] - 2025-03-31

- Added `tool_call_completed` for `Iterator`

## [0.7.9] - 2025-03-24

- Added `uri_base` for configuration

## [0.7.8] - 2025-03-22

- Added support for alternative model providers

## [0.7.6] - 2025-03-12

- Update Task model enum syntax to Rails 7 style

## [0.7.5] - 2025-03-01

- Improved handling of truncated responses in Iterator
- Updated dependencies

## [0.7.4] - 2024-08-25

- Fixed `finish_it` for `Iterator`

## [0.7.2] - 2024-08-25

- Fixed tool calls in `Iterator`

## [0.7.1] - 2024-08-24

- Added retry for `Iterator`

## [0.7.0] - 2024-08-24

- Added `finish` for `Iterator`
- Added `after_finish` for `Iterator`

## [0.6.3] - 2024-08-24

- Added `add_raw_context` for `Iterator`
- Fixed `requested?`

## [0.6.2] - 2024-08-24

- Rails ActiveRecord support

## [0.6.0] - 2024-08-02

- Added rails compatibility
- Added `wait_for_complete` option

## [0.5.8] - 2024-08-02

- Fixed gem `state_machines`

## [0.5.7] - 2024-08-02

- Added monkey patch for `full_function_name`

## [0.5.6] - 2024-08-02

- Added `oxaiworkers run` command

## [0.5.5] - 2024-08-02

- Added `only` for Tools
- Addded `locale` for `Iterator` and `Assistant`

## [0.5.4] - 2024-08-01

- def_except and def_only for `Iterator`
- Renamed on_pack_history to on_summarize
- Renamed all "pack_history" to "summarize"

## [0.5.3] - 2024-07-31

- Fixed summarize state
- Added `auto_execute` for `Iterator`
- Added `steps` for `Iterator`

## [0.5.2] - 2024-07-31

- Added new assistant: `Localizer`
- Added logger

## [0.5.1] - 2024-07-30

- Improved FileSystem functionality
- Catch errors when eval sh command
- Fixed `execute` in Iterator

## [0.5.0] - 2024-07-30

- snake_cased function names

## [0.4.2] - 2024-07-30

- Binary reading is suppressed
- Command output code is returned if the command output is empty
- Fixed roles when calling functions.

## [0.4.0] - 2024-07-30

- Added tools: `file_system`, `database`
- Added assistant: `coder`

## [0.3.2] - 2024-07-30

- Friendly I18n

## [0.3.0] - 2024-07-30

- on_inner_monologue: ->(text:) { puts "monologue: #{text}" }
- on_outer_voice: ->(text:) { puts "voice: #{text}" }
- on_action_request: ->(text:) { puts "action: #{text}" }
- on_pack_history: ->(text:) { puts "summary: #{text}" }

## [0.2.5] - 2024-07-30

- Improved start template

## [0.2.4] - 2024-07-30

- Complete template for initialization: `oxaiworkers init full`
- Fix missing require_relative

## [0.2.3] - 2024-07-30

- Added start script with configuration section

## [0.2.2] - 2024-07-30

- Fixed CLI issues
- Improved start script (CLI: .oxaiworkers-local/start)
- Enhanced initialization script

## [0.2.0] - 2024-07-30

- Fixed missing require 'open3'
- Corrected execution steps
- CLI: added command `oxaiworkers init`

## [0.1.1] - 2024-07-29

- Fixed delayed requests
- Added configurable parameters for model, max_tokens, temperature

## [0.1.0] - 2024-07-29

- Initial release
