# frozen_string_literal: true

require_relative "lib/remote_sh/version"

Gem::Specification.new do |spec|
  spec.name = "remote_sh"
  spec.version = RemoteSh::VERSION
  spec.authors = ["Pavel Egorov"]
  spec.email = ["moonmeander47@ya.ru"]

  spec.summary = "CLI for remote development"
  spec.description = "CLI for remote development"
  spec.homepage = "https://github.com/emfy0/remote_sh"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/emfy0/remote_sh"

  spec.files = Dir['lib/**/*.rb', 'exe/**/*', 'README.md']
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency 'filewatcher'
  spec.add_dependency 'thor'
  spec.add_dependency 'zeitwerk'
  spec.add_dependency 'webrick'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
