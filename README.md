# Benchmark::Driver [![Build Status](https://travis-ci.org/k0kubun/benchmark_driver.svg?branch=master)](https://travis-ci.org/k0kubun/benchmark_driver)

Fully-featured accurate benchmark driver for Ruby

## Project Status

**Under Construction**

## Features
NOTE: Pending ones are ~slashed~.

### Accurate Measurement

- Low overhead benchmark by running generated script instead of calling Proc
- Running multiple times to minimize measurement errors
- Profiling memory, high-precision real time, ~user time and system time~

### Pluggable & Fully Featured

- Flexible and real-time output format in ips, execution time, ~markdown table~, etc.
- Output format is pluggable
- ~Integrated benchmark support using external libraries~

### Flexible Interface

- YAML input to easily manage structured benchmark set
- Comparing multiple Ruby binaries, even with miniruby

## Installation

```
$ gem install benchmark_driver
```

## Usage

With `benchmark-driver` command, you can describe benchmark with YAML input.

```
$ benchmark-driver -h
Usage: benchmark-driver [options] [YAML]
    -e, --executables [EXECS]        Ruby executables (e1::path1; e2::path2; e3::path3;...)
        --rbenv [VERSIONS]           Ruby executables in rbenv (2.3.5;2.4.2;...)
    -c, --compare                    Compare results (currently only supported in ips output)
    -r, --repeat-count [NUM]         Try benchmark NUM times and use the fastest result
```

### Running single script

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

### Running multiple scripts

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
- [x] Exec
- [ ] Eval

### Output
- [x] IPS
- [x] Time
- [x] Memory
- [ ] CPU/System/Real Time
- [ ] Markdown Table

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/k0kubun/benchmark_driver.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
