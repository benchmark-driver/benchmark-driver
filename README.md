# Benchmark::Driver [![Build Status](https://travis-ci.org/k0kubun/benchmark_driver.svg?branch=master)](https://travis-ci.org/k0kubun/benchmark_driver)

Fully-featured accurate benchmark driver for Ruby

## Project Status

**Under Construction**

## Features
### Accurate Measurement

- Low overhead benchmark by running generated script instead of calling Proc
- Profiling memory, high-precision real time, user time and system time
- Running multiple times to minimize measurement errors

### Pluggable & Fully Featured

- Flexible and real-time output format in ips, execution time, markdown table, etc.
- Benchmark with various profiling/running options
- Integrated benchmark support using external libraries
- Runner, profiler and output format are all pluggable

### Flexible Interface

- Ruby interface similar to benchmark stdlib, benchmark-ips
- YAML input to easily manage structured benchmark set
- Comparing multiple Ruby binaries, even with miniruby

## Installation

```
$ gem install benchmark_driver
```

## Usage

### Ruby Interface: Compatible Mode

This interface is compatible with `Benchmark.bm` and `Benchmark.ips`, so it's good for migration.

```rb
require 'benchmark/driver'
require 'active_support/all'
array = []

Benchmark.drive do |x|
  x.report('blank?') { array.blank? }
  x.report('empty?') { array.empty? }
  x.compare!
end
```

### Ruby Interface: Low Overhead Mode

This interface generates code to profile with low overhead and executes it.

```rb
require 'benchmark/driver'

Benchmark.drive do |x|
  x.prelude = <<~RUBY
    require 'active_support/all'
    array = []
  RUBY

  x.report('blank?', script: 'array.blank?')
  x.report('empty?', script: 'array.empty?')
end
```

or simply:

```rb
require 'benchmark/driver'

Benchmark.drive do |x|
  x.prelude = <<~RUBY
    require 'active_support/all'
    array = []
  RUBY

  x.report(script: 'array.blank?')
  x.report(script: 'array.empty?')
end
```

### Structured YAML Input

TBD

## TODO
### Runner
- [x] Call
  - [x] Duration
  - [ ] Loop Count
- [x] Exec
  - [x] Duration
  - [ ] Loop Count
  - [ ] While <=> Long script

### Profiler
- [ ] Real Time
- [ ] CPU/System/Real Time
- [ ] Memory

### Output
- [x] IPS
  - [x] Compare
- [ ] Time
- [ ] Markdown Table

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/k0kubun/benchmark_driver.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
