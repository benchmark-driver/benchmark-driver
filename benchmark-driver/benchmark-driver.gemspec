# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "benchmark-driver"
  spec.version       = "0.1.0"
  spec.authors       = ["bmarkons"]
  spec.email         = ["mamaveb@gmail.com"]

  spec.summary       = %q{Alias gem to install benchmark_driver.gem}
  spec.homepage      = "https://github.com/benchmark-driver/benchmark-driver"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "benchmark_driver"
end
