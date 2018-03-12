# coding: utf-8
$LOAD_PATH << File.expand_path('../opal', __FILE__)
require 'tone/version'

Gem::Specification.new do |spec|
  spec.name          = "opal-tone"
  spec.version       = Tone::VERSION
  spec.authors       = ["Jose Añasco"]
  spec.email         = ["joseanasco1@gmail.com"]

  spec.summary       = %q{Ruby wrapper around Tone.js}
  spec.description   = %q{Web audio framework in Ruby}
  spec.homepage      = "http://github.com/merongivian/tone.rb"

  spec.files          = `git ls-files`.split("\n")
  spec.executables    = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  spec.test_files     = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.require_paths  = ['lib']

  spec.add_runtime_dependency 'opal', '>= 0.10.2'
  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
end
