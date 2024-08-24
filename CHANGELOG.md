## [Unreleased]

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