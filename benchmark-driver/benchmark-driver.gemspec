# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'benchmark/driver/version'

Gem::Specification.new do |spec|
  spec.name          = "benchmark-driver"
  spec.version       = Benchmark::Driver::VERSION
  spec.authors       = ["bmarkons"]
  spec.email         = ["mamaveb@gmail.com"]

  spec.summary       = %q{Benchmark driver used to run all benchmarks on RubyBench}
  spec.homepage      = "https://github.com/bmarkons/benchmark-driver"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
