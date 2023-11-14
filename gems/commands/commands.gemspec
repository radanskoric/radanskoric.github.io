# frozen_string_literal: true

require_relative "lib/commands/version"

Gem::Specification.new do |spec|
  spec.name = "commands"
  spec.version = Commands::VERSION
  spec.authors = ["Radan Skorić"]
  spec.email = ["radan.skoric@gmail.com"]

  spec.summary = "Custom commands for my personal site."
  spec.required_ruby_version = ">= 2.6.0"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
