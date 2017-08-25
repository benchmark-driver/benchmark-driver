# BenchmarkDriver

Benchmark driver for different Ruby executables

## Installation

    $ gem install benchmark_driver

## Usage

```
$ benchmark_driver -h
Usage: benchmark_driver [options]
    -e, --executables [EXECS]        Specify benchmark one or more targets (e1::path1; e2::path2; e3::path3;...)
    -d, --directory [DIRECTORY]      Benchmark suites directory
    -p, --pattern [PATTERN]          Benchmark name pattern
    -x, --exclude [PATTERN]          Benchmark exclude pattern
    -r, --repeat-count [NUM]         Repeat count
    -o, --output-file [FILE]         Output file
        --ruby-arg [ARG]             Optional argument for ruby
        --measure-target [TARGET]    real (execution time), peak, size (memory)
        --rawdata-output [FILE]      output rawdata
        --load-rawdata=FILE          input rawdata
    -f, --format=FORMAT              output format (tsv,markdown,plain)
    -v, --verbose
    -q, --quiet                      Run without notify information except result table.
```

### Single benchmark for current Ruby executable

```bash
benchmark_driver -c config.yml
```

### Single benchmark for multiple Ruby executables

```bash
benchmark_driver -c config.yml
```

### Multiple benchmarks for current Ruby executable

```bash
benchmark_driver -c config.yml
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/k0kubun/benchmark_driver.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
