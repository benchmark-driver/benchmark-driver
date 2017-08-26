# BenchmarkDriver [![Build Status](https://travis-ci.org/k0kubun/benchmark_driver.svg?branch=master)](https://travis-ci.org/k0kubun/benchmark_driver)

Benchmark driver for different Ruby executables

## Installation

    $ gem install benchmark_driver

## Usage

```
$ exe/benchmark_driver -h
Usage: benchmark_driver [options] [YAML]
    -e, --executables [EXECS]        Ruby executables (e1::path1; e2::path2; e3::path3;...)
    -i, --ips [SECONDS]              Measure IPS in duration seconds (default: 1)
    -l, --loop-count [COUNT]         Measure execution time with loop count (default: 100000)
    -v, --verbose
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
$ exe/benchmark_driver ruby_benchmark_set/example_single.yml -e ruby1::ruby -e ruby2::ruby
benchmark results:
Execution time (sec)
name             ruby1    ruby2
example_single   0.958    0.972

Speedup ratio: compare with the result of `ruby1' (greater is better)
name             ruby2
example_single   0.986
```

And you can change benchmark output to IPS (iteration per second) by `-i` option.

```
$ exe/benchmark_driver ruby_benchmark_set/example_single.yml -e ruby1::ruby -e ruby2::ruby -i
Result -------------------------------------------
                         ruby1          ruby2
  example_single   99414.1 i/s    99723.3 i/s

Comparison: example_single
           ruby2:      99723.3 i/s
           ruby1:      99414.1 i/s - 1.00x slower
```

### Running multiple scripts

One YAML file can contain multiple benchmark scripts.
With following `example_multi.yml`,

```yml
prelude: |
  a = 'a' * 100
  b = 'b' * 100
benchmarks:
  - name: join
    benchmark: |
      [a, b].join
  - name: interpolation
    benchmark: |
      "#{a}#{b}"
```

you can benchmark the scripts with multiple ruby executables.

```
$ exe/benchmark_driver ruby_benchmark_set/example_multi.yml -e ruby1::ruby -e ruby2::ruby
benchmark results:
Execution time (sec)
name             ruby1    ruby2
join             0.022    0.022
interpolation    0.026    0.026

Speedup ratio: compare with the result of `ruby1' (greater is better)
name             ruby2
join             1.045
interpolation    1.002
```

```
$ exe/benchmark_driver ruby_benchmark_set/example_multi.yml -e ruby1::ruby -e ruby2::ruby -i
Result -------------------------------------------
                         ruby1          ruby2
            join 4701954.3 i/s  4639520.3 i/s
   interpolation 4263170.0 i/s  4044083.0 i/s

Comparison: join
           ruby1:    4701954.3 i/s
           ruby2:    4639520.3 i/s - 1.01x slower

Comparison: interpolation
           ruby1:    4263170.0 i/s
           ruby2:    4044083.0 i/s - 1.05x slower
```

### Configuring modes

There are 2 modes:

- Loop count: Enabled by `-l`. Optionally you can change count to loop by `-l COUNT`.
- IPS: Enabled by `-i`. Optionally you can change duration by `-i DURATION`.

Specifying both `-l` and `-i` is nonsense.

### YAML syntax
You can specify `benchmark:` or `benchmarks:`.

#### Single
```yml
name: String (default: file name)
prelude: String
loop_count: Integer
benchmark: String
```

#### Multi

```yml
prelude: String (shared)
loop_count: Integer (shared)
benchmarks:
  - name: String
    prelude: String (benchmark specific)
    loop_count: Integer (benchmark specific)
    benchmark: String
```

### Debugging

If you have a trouble like an unexpectedly fast result, you should check benchmark script by `-v`.

```
$ exe/benchmark_driver ruby_benchmark_set/example_multi.yml -v
--- Running "join" with "ruby" 957780 times ---
a = 'a' * 100
b = 'b' * 100


i = 0
while i < 957780
  i += 1
[a, b].join

end
```

## TODO

- Measure multiple times and use minimum result
- Retry and reject negative result in ips mode
- Change not to take long time for iteration count estimation in ips mode

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/k0kubun/benchmark_driver.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
