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
- Runner and output are all pluggable

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

With `benchmark-driver` command, you can describe benchmark with YAML input.

```
$ exe/benchmark-driver -h
Usage: benchmark-driver [options] [YAML]
    -e, --executables [EXECS]        Ruby executables (e1::path1; e2::path2; e3::path3;...)
        --rbenv [VERSIONS]           Ruby executables in rbenv (2.3.5;2.4.2;...)
    -c, --compare
```

#### Running single script

With following `example_single.yml`,

```yml
prelude: |
  require 'erb'
  erb = ERB.new(%q[Hello <%= 'World' %>])
benchmark: erb.result
```

you can benchmark the script with multiple ruby executables.

```
$ exe/benchmark-driver examples/yaml/example_single.yml --rbenv '2.4.2;trunk' --compare
Warming up --------------------------------------
          erb.result    10.973k i/100ms
Calculating -------------------------------------
                          2.4.2       trunk
          erb.result   109.268k    123.611k i/s -    548.675k in 4.017080s 4.438720s

Comparison:
  erb.result (trunk):    123611.1 i/s
  erb.result (2.4.2):    109268.4 i/s - 1.13x  slower
```

#### Running multiple scripts

One YAML file can contain multiple benchmark scripts.
With following `example_multi.yml`,

```yml
prelude: |
  a = 'a' * 100
  b = 'b' * 100
benchmark:
  join: '[a, b].join'
  str-interp: '"#{a}#{b}"'
```

you can benchmark the scripts with multiple ruby executables.

```
$ exe/benchmark-driver examples/yaml/example_multi.yml --rbenv '2.4.2;trunk' --compare
Warming up --------------------------------------
                join   515.787k i/100ms
          str-interp   438.646k i/100ms
Calculating -------------------------------------
                          2.4.2       trunk
                join     5.200M      4.740M i/s -     20.631M in 3.967750s 4.352565s
          str-interp     4.306M      6.034M i/s -     21.932M in 4.075159s 3.634986s

Comparison:
  str-interp (trunk):   6033674.6 i/s
        join (2.4.2):   5199794.6 i/s - 1.16x  slower
        join (trunk):   4740075.1 i/s - 1.27x  slower
  str-interp (2.4.2):   4305563.1 i/s - 1.40x  slower
```

## TODO
### Runner
- [x] Call
  - [x] Duration
- [x] Exec
  - [x] Duration
  - [ ] While <=> Long script

### Output
- [x] IPS
  - [x] Compare
- [x] Time
- [ ] CPU/System/Real Time
- [ ] Memory
- [ ] Markdown Table

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/k0kubun/benchmark_driver.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
