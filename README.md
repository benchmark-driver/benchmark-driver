# BenchmarkDriver

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

With following `bm_app_erb.yml`,

```yml
prelude: |
  require 'erb'

  title = "hello world!"
  content = "hello world!\n" * 10

  data = <<EOS
  <html>
    <head> <%= title %> </head>
    <body>
      <h1> <%= title %> </h1>
      <p>
        <%= content %>
      </p>
    </body>
  </html>
  EOS

benchmark: |
  ERB.new(data).result(binding)
```

you can benchmark the script with multiple ruby executables.

```
$ benchmark_driver bm_app_erb.yml -e ruby1::ruby -e ruby2::ruby
benchmark results:
Execution time (sec)
name             ruby1    ruby2
bm_app_erb       1.028    1.010

Speedup ratio: compare with the result of `ruby1' (greater is better)
name             ruby2
bm_app_erb       1.018
```

And you can change benchmark output by `-r` option.

```
$ benchmark_driver bm_app_erb.yml -e ruby1::ruby -e ruby2::ruby -r ips
Result -------------------------------------------
                         ruby1          ruby2
      bm_app_erb   16082.8 i/s    15541.7 i/s

Comparison: bm_app_erb
           ruby1:      16082.8 i/s
           ruby2:      15541.7 i/s - 1.03x slower
```

### Running multiple scripts

One YAML file can contain multiple benchmark scripts.
With following `erb_compile_render.yml`,

```yml
- name: erb_compile
  prelude: |
    require 'erb'

    title = "hello world!"
    content = "hello world!\n" * 10

    data = <<EOS
    <html>
      <head> <%= title %> </head>
      <body>
        <h1> <%= title %> </h1>
        <p>
          <%= content %>
        </p>
      </body>
    </html>
    EOS

  benchmark: |
    ERB.new(data).src

- name: erb_render
  prelude: |
    require 'erb'

    title = "hello world!"
    content = "hello world!\n" * 10

    data = <<EOS
    <html>
      <head> <%= title %> </head>
      <body>
        <h1> <%= title %> </h1>
        <p>
          <%= content %>
        </p>
      </body>
    </html>
    EOS

    src = "def self.render(title, content); #{ERB.new(data).src}; end"
    mod = Module.new
    mod.instance_eval(src, "(ERB)")

  benchmark: |
    mod.render(title, content)
```

you can benchmark the scripts with multiple ruby executables.

```
$ benchmark_driver erb_compile_render.yml -e ruby1::ruby -e ruby2::ruby
benchmark results:
Execution time (sec)
name             ruby1    ruby2
erb_compile      0.987    0.985
erb_render       0.834    0.809

Speedup ratio: compare with the result of `ruby1' (greater is better)
name             ruby2
erb_compile      1.002
erb_render       1.031
```

```
$ benchmark_driver erb_compile_render.yml -e ruby1::ruby -e ruby2::ruby -r ips
Result -------------------------------------------
                         ruby1          ruby2
     erb_compile   30374.0 i/s    30832.1 i/s
      erb_render  628403.5 i/s   624588.0 i/s

Comparison: erb_compile
           ruby2:      30832.1 i/s
           ruby1:      30374.0 i/s - 1.02x slower

Comparison: erb_render
           ruby1:     628403.5 i/s
           ruby2:     624588.0 i/s - 1.01x slower
```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/k0kubun/benchmark_driver.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
