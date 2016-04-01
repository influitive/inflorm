# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'inflorm/version'

Gem::Specification.new do |spec|
  spec.name          = "inflorm"
  spec.version       = Inflorm::VERSION
  spec.authors       = ["Brad Robertson"]
  spec.email         = ["brad@influitive.com"]

  spec.summary       = %q{Simple Form Objects}
  spec.description   = %q{Form Objects with no assumptions about persistence and a clean api for associations/validations}
  spec.homepage      = "https://github.com/influitive/inflorm"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_dependency "activemodel", ">= 4.2", "<= 5.0"
  spec.add_dependency "virtus", "~> 1.0"
end
