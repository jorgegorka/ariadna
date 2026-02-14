require_relative "lib/ariadna/version"

Gem::Specification.new do |s|
  s.name        = "ariadna"
  s.version     = Ariadna::VERSION
  s.summary     = "A meta-prompting and context engineering system for Claude Code"
  s.description = "Ariadna ports the GSD (Get Shit Done) system to Ruby, providing structured " \
                  "planning, multi-agent orchestration, and verification workflows via Claude Code " \
                  "slash commands."
  s.authors     = ["Jorge Alvarez"]
  s.email       = "jorge@alvareznavarro.es"
  s.homepage    = "https://github.com/jorgemanrubia/ariadna"
  s.license     = "MIT"

  s.required_ruby_version = ">= 3.1.0"

  s.files = Dir.chdir(__dir__) do
    Dir["{lib,exe,data}/**/*", "LICENSE", "*.gemspec"].reject { |f| File.directory?(f) }
  end

  s.bindir      = "exe"
  s.executables  = %w[ariadna ariadna-tools]

  s.metadata = {
    "homepage_uri"    => s.homepage,
    "source_code_uri" => s.homepage,
    "changelog_uri"   => "#{s.homepage}/blob/main/CHANGELOG.md"
  }
end
