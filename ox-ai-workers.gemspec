# frozen_string_literal: true

require_relative 'lib/oxaiworkers/version'

Gem::Specification.new do |spec|
  spec.name = 'ox-ai-workers'
  spec.version = OxAiWorkers::VERSION
  spec.authors = ['Denis Smolev']
  spec.email = ['smolev@me.com']

  spec.summary = 'A powerful state machine with OpenAI generative intelligence integration'
  spec.description = <<-DESC
    OxAiWorkers (ox-ai-workers) is a cutting-edge Ruby gem designed to seamlessly integrate
    a sophisticated state machine with the powerful capabilities of generative intelligence
    via the ruby-openai gem. This innovative tool empowers developers to construct state machines
    that efficiently handle complex tasks, enhancing outcomes by combining robust internal
    logic with advanced AI-driven decision-making. Key features include straightforward creation
    and management of state machines, harnessing AI for improved decision-making and task
    execution, customizable behavior to suit specific requirements, and user-friendly syntax
    and documentation for a smooth development experience.
  DESC

  spec.homepage = 'https://ai.oxteam.me'
  spec.license = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.2.0')

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/neonix20b/ox-ai-workers'
  spec.metadata['changelog_uri'] = 'https://github.com/neonix20b/ox-ai-workers/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = ['oxaiworkers']
  spec.require_paths = ['lib']

  spec.add_dependency 'colorize', '~> 1'
  spec.add_dependency 'faraday', '>= 1'
  spec.add_dependency 'faraday-multipart', '>= 1'
  spec.add_dependency 'i18n', '>= 1'
  spec.add_dependency 'ptools', '>= 1'
  spec.add_dependency 'ruby-openai', '>= 7'
  spec.add_dependency 'state_machines', '>= 0.6'
end
