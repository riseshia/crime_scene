# frozen_string_literal: true

require_relative "lib/crime_scene/version"

Gem::Specification.new do |spec|
  spec.name          = "crime_scene"
  spec.version       = CrimeScene::VERSION
  spec.authors       = ["Shia"]
  spec.email         = ["rise.shia@gmail.com"]

  spec.summary       = "CrimeScene"
  spec.description   = "CrimeScene"
  spec.homepage      = "https://github.com/riseshia/crime_scene"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/riseshia/crime_scene"
  spec.metadata["changelog_uri"] = "https://github.com/riseshia/crime_scene"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "coffee-script"
  spec.add_dependency "haml"
  spec.add_dependency "parser"
  spec.add_dependency "zeitwerk"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
