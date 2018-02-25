# BenchmarkDriver [![Build Status](https://travis-ci.org/k0kubun/benchmark_driver.svg?branch=master)](https://travis-ci.org/k0kubun/benchmark_driver)

Fully-featured accurate benchmark driver for Ruby

## Project Status

Beta.

Interface might be changed in the future, but it's almost fixed and many features can run well.

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

### Ruby Interface

This interface generates code to profile with low overhead and executes it.

```rb
require 'benchmark_driver'

Benchmark.drive do |x|
  x.prelude = <<~RUBY
    require 'active_support/all'
    array = []
  RUBY

  x.report 'blank?', %{ array.blank? }
  x.report 'empty?', %{ array.empty? }
end
```

or simply:

```rb
require 'benchmark_driver'

Benchmark.drive do |x|
  x.prelude = <<~RUBY
    require 'active_support/all'
    array = []
  RUBY

  x.report %{ array.blank? }
  x.report %{ array.empty? }
end
```

### Structured YAML Input

With `benchmark-driver` command, you can describe benchmark with YAML input.

```
$ benchmark-driver -h
Usage: benchmark-driver [options] [YAML]
    -r, --runner [TYPE]              Specify runner type: ips, time, memory (default: ips)
    -o, --output [TYPE]              Specify output type: compare, simple, markdown (default: compare)
    -e, --executables [EXECS]        Ruby executables (e1::path1,arg1,...; e2::path2,arg2;...)
        --rbenv [VERSIONS]           Ruby executables in rbenv (x.x.x,arg1,...;y.y.y,arg2,...;...)
        --repeat-count [NUM]         Try benchmark NUM times and use the fastest result (TODO)
        --bundler                    Install and use gems specified in Gemfile
        --filter [REGEXP]            Filter out benchmarks with given regexp
        --run-duration [SECONDS]     Warmup esitmates loop_count to run for this duration (default: 3)
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
$ benchmark-driver example_single.yml --rbenv '2.4.1;2.5.0'
Warming up --------------------------------------
          erb.result    71.683k i/s
Calculating -------------------------------------
                          2.4.1       2.5.0
          erb.result    72.387k     75.046k i/s -    215.049k times in 2.970833s 2.865581s

Comparison:
                       erb.result
               2.5.0:     75045.5 i/s
               2.4.1:     72386.8 i/s - 1.04x  slower
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
$ benchmark-driver example_multi.yml --rbenv '2.4.1;2.5.0'
Warming up --------------------------------------
                join     2.509M i/s
          str-interp     1.772M i/s
Calculating -------------------------------------
                          2.4.1       2.5.0
                join     2.661M      2.863M i/s -      7.527M times in 2.828771s 2.629191s
          str-interp     1.890M      3.258M i/s -      5.315M times in 2.812240s 1.630997s

Comparison:
                             join
               2.5.0:   2862755.1 i/s
               2.4.1:   2660777.4 i/s - 1.08x  slower

                       str-interp
               2.5.0:   3258489.7 i/s
               2.4.1:   1889805.6 i/s - 1.72x  slower
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/k0kubun/benchmark_driver.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
