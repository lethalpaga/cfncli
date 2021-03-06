# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cfncli/version'

Gem::Specification.new do |spec|
  spec.name          = "cfncli"
  spec.version       = CfnCli::VERSION
  spec.authors       = ["lethalpaga"]
  spec.email         = ["lethalpaga@gmail.com"]

  spec.summary       = %q{Creates cloudformation stacks}
  spec.description   = %q{Creates a Cloudformation stack synchronously}
  spec.homepage      = "https://github.com/lethalpaga/cfncli"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-its", "~>1.2"
  spec.add_development_dependency "cucumber", "~> 2"
  spec.add_development_dependency "guard", "~> 2"
  spec.add_development_dependency "guard-rspec"
 
  spec.add_dependency "thor"
  spec.add_dependency "aws-sdk-cloudformation", "~> 1"
  spec.add_dependency "waiting", "~> 0"
  spec.add_dependency "activesupport", ">= 4", "< 6"
  spec.add_dependency "colorize", "~> 0"
  spec.add_dependency "concurrent-ruby", "~> 1.0"
end
