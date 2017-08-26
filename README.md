# BenchmarkDriver [![Build Status](https://travis-ci.org/k0kubun/benchmark_driver.svg?branch=master)](https://travis-ci.org/k0kubun/benchmark_driver)

Benchmark driver for different Ruby executables

## Installation

    $ gem install benchmark_driver

## Usage

```
$ benchmark_driver -h
Usage: benchmark_driver [options] [YAML]
    -d, --duration [SECONDS]         Duration seconds to run each benchmark (default: 1)
    -e, --executables [EXECS]        Ruby executables (e1::path1; e2::path2; e3::path3;...)
    -r, --result-format=FORMAT       Result output format [time|ips] (default: time)
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
example_single   0.986    1.009

Speedup ratio: compare with the result of `ruby1' (greater is better)
name             ruby2
example_single   0.978
```

And you can change benchmark output by `-r` option.

```
$ exe/benchmark_driver ruby_benchmark_set/example_single.yml -e ruby1::ruby -e ruby2::ruby -r ips
Result -------------------------------------------
                         ruby1          ruby2
  example_single  104247.7 i/s   103797.0 i/s

Comparison: example_single
           ruby1:     104247.7 i/s
           ruby2:     103797.0 i/s - 1.00x slower
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
join             0.146    0.150
interpolation    0.287    0.302

Speedup ratio: compare with the result of `ruby1' (greater is better)
name             ruby2
join             0.969
interpolation    0.951
```

```
$ exe/benchmark_driver ruby_benchmark_set/example_multi.yml -e ruby1::ruby -e ruby2::ruby -r ips
Result -------------------------------------------
                         ruby1          ruby2
            join 4723764.9 i/s  4595744.3 i/s
   interpolation 4265934.5 i/s  4189385.4 i/s

Comparison: join
           ruby1:    4723764.9 i/s
           ruby2:    4595744.3 i/s - 1.03x slower

Comparison: interpolation
           ruby1:    4265934.5 i/s
           ruby2:    4189385.4 i/s - 1.02x slower
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

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/k0kubun/benchmark_driver.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
