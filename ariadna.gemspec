# -*- encoding: utf-8 -*-
require File.expand_path('../lib/ariadna/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jorge Alvarez"]
  gem.email         = ["jorge@alvareznavarro.es"]
  gem.description   = %q{Google Analytics A.P.I. V3 wrapper with oauth2}
  gem.summary       = %q{Google Analytics A.P.I. V3 wrapper with oauth2}
  gem.homepage      = "https://github.com/jorgegorka/ariadna"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "ariadna"
  gem.require_paths = ["lib"]
  gem.version       = Ariadna::VERSION
  gem.add_development_dependency "pry"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "guard-rspec"
end
