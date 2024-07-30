## [Unreleased]

## [0.3.2] - 2024-07-30

- Friendly I18n

## [0.3.0] - 2024-07-30

- on_inner_monologue: ->(text:) { puts Rainbow("monologue: #{text}").yellow }
- on_outer_voice: ->(text:) { puts Rainbow("voice: #{text}").green }
- on_action_request: ->(text:) { puts Rainbow("action: #{text}").red }
- on_pack_history: ->(text:) { puts Rainbow("summary: #{text}").blue }

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