# v0.16.2

- Add --chruby option to use a Ruby managed by chruby

# v0.16.1

- Add --output-humanize option to --output=simple

# v0.16.0

- Support benchmarking inline Ruby scripts [#75](https://github.com/benchmark-driver/benchmark-driver/pull/75)
- Require Ruby 2.5+
- Fix `recorded` runner for Ruby 3.1's Psych

# v0.15.18

- Mention `--output=all` in help

# v0.15.17

- Jobs returned from job parsers are made mutable for plugins

# v0.15.16

- Add `--alternate` runner option to run executables alternately.
  This is supported only for `ruby_stdout` runner for now.

# v0.15.15

- An absolute path is passed to `command_stdout`'s `working_directory`
  and v0.15.14's relative path resolution of job type

# v0.15.14

- YAML's `type` key allows a value with `/` to specify a relative path of a runner plugin

# v0.15.13

- Show a command and stdout on `-vv` for `ips`, `time`, and `block` runner

# v0.15.12

- Show comparison on `--output=markdown` when `--output-compare` is also specified

# v0.15.11

- Correctly calculate an average result on `--repeat-result=average`

# v0.15.10

- Right-justify calculated results in `markdown` output

# v0.15.9

- Prefer an exact match in RVM version selection
- Fix a negative duration crash in `ips`, `time` and `once` runners
- Fix bugs in old TruffleRuby not supporting `keyword_init` of Struct

# v0.15.8

- Add `--rvm` option and `.rvm` Ruby interface to use RVM

# v0.15.7

- Add `median` to --repeat-result options

# v0.15.6

- Fix new keyword argument warnings for the latest Ruby 2.7

# v0.15.5

- Propagate `RUBYOPT` to a runner process when executables are not specified
  - This effectively propagates `bundle exec` to child processes
- Fix unused variable warning in `benchmark_driver/ridkuse.rb`
- Fix keyword argument warnings for Struct in Ruby 2.7

# v0.15.4

- Avoid showing error messages by CLI's rbenv check introduced in v0.15.0

# v0.15.3

- Add `--ridkuse` to select Ruby by `ridk use` if `ridk` command is available

# v0.15.2

- `recorded` runner propagates `all_values` to output

# v0.15.1

- `BenchmarkDriver::BulkOutput#initialize` takes `options` option for `super`

# v0.15.0

- Introduce output plugin interface to accept arbitrary `--output-xxx` option
- Hide `--rbenv` option when `rbenv` command is not available

# v0.14.22

- Fix warnings for keyword arguments in Ruby 2.7

# v0.14.21

- Avoid crashinig on a zero division error in `compare` output
  [#56](https://github.com/benchmark-driver/benchmark-driver/pull/56)

# v0.14.20

- Add `block` runner to automatically wrap a Ruby block in script for benchmarking MJIT

# v0.14.19

- Improve v0.14.18's Bundler integration for ruby/ruby's `make run`

# v0.14.18

- Support loading benchmark\_driver.rb with --disable-gems

# v0.14.17

- Fix deprecation warning: "`Bundler.with_clean_env` has been deprecated"

# v0.14.16

- Output ERROR metrics for a command failure on ruby\_stdout runner instead of crashing it

# v0.14.15

- Remove an extra space from markdown output
  [#55](https://github.com/benchmark-driver/benchmark-driver/pull/55)

# v0.14.14

- Add `all` output plugin to compare all sorted results

# v0.14.13

- Add macOS support to memory runner
  [#53](https://github.com/benchmark-driver/benchmark-driver/pull/53)

# v0.14.12

- Reduce the risk of random ZeroDivisionError on warmup
  [#52](https://github.com/benchmark-driver/benchmark-driver/pull/52)

# v0.14.11

- Add `x.executable` method to Ruby interface for specifying Ruby executable which is not managed by rbenv
  [#50](https://github.com/benchmark-driver/benchmark-driver/pull/50)

# v0.14.10

- Resolve internal Ruby warnings

# v0.14.9

- Allow recorded runner to run without the recorded Ruby executables
  [#43](https://github.com/benchmark-driver/benchmark-driver/issues/43) [#44](https://github.com/benchmark-driver/benchmark-driver/issues/44)

# v0.14.8

- Fix bug that "benchmark\_driver.record.yml" created with `-e`/`--rbenv` option
  has required to specify the same `-e`/`--rbenv` option [#42](https://github.com/benchmark-driver/benchmark-driver/issues/42)

# v0.14.7

- Fix bug on warmup with `BenchmarkDriver::BulkOutput` [#40](https://github.com/benchmark-driver/benchmark-driver/issues/40)
  - This is currently used by benchmark\_driver-output-gruff

# v0.14.6

- Improve option parser validation
- Add `--timeout` option only for Linux having timeout(1)
- Support `--version` option
- Fix help output for `-e`/`--rbenv` in benchmark-driver command

# v0.14.5

- Fix wrong spacing format in simple / markdown output

# v0.14.4

- Fix runners and outputs to distinguish 0.0 and ERROR value

# v0.14.3

- Support loading runner plugin

# v0.14.2

- Fix definitive error in v0.14.1...

# v0.14.1 (yanked)

- Fix `BenchmarkDriver::BulkOutput` error on contexts with prelude [#38](https://github.com/benchmark-driver/benchmark-driver/issues/38)

# v0.14.0

- `benchmark-driver` command also takes `*.rb` file to run single-execution benchmark
  - Non-`*.rb` filename is considered as YAML file as before
- [breaking change] `--verbose` no longer takes LEVEL argument
  - Added `-v` for `-v`/`-vv` instead of `--verbose 1` and `--verbose 2`.
  - `--verbose --verbose` can also be used instead of `--verbose 2` if you want.
- [breaking change] Use ` `(space) to split Ruby arguments in `-e`/`--executables`/`--rbenv`
  - ex) `-e "/path/to/ruby --jit"` should be used instead of `-e "/path/to/ruby,--jit"`
- [experimental] Return 0.0 as value when benchmark script fails on ips/time/memory/once runners
  - Exit status is 0 for that case. `benchmark-driver` exits abnormaly only on its internal bug.

# v0.13.3

- Support `require: false` in contexts to skip automatic requirement with a gem name

# v0.13.2

- Stop generating loop code with `loop_count: 1` on ips runner

# v0.13.1

- Respect a magic comment in `prelude`

# v0.13.0

- Add support for benchmark with different versions of gems and preludes
  - Only YAML is supported for now, Ruby interface will come later
- [breaking change] Runner plugin interface is slightly changed

# v0.12.0

- [breaking change] Plugin interface is changed again
- Fix bugs in a case that multiple YAMLs with different types are specified
- Output plugin is now ensured to yield the same metrics

# v0.11.1

- Add `--repeat-result` option to return the best, the worst or an average result with `--repeat-count`
- Add `BenchmarkDriver::BulkOutput` to make an output plugin casually

# v0.11.0

- [breaking change] Plugin interface is completely changed, so all plugins need migration
  - YAML/Ruby interface is not changed at all
  - Now the internal model allows to have multiple metrics in the same job,
    but having multiple metrics is still not respected by built-in plugins
  - "executable" is renamed to be "context", but still configuring a context
    other than an executable is not supported yet
  - A metric can have a name
- Add `ruby_stdout` runner
  - This can parse an arbitrary "environment" for the "context"
  - Metric can have name
- Metric name is shwon on some outputs like markdown and simple
- `--run-duration` accepts floating-point number
- News: Now benchmark-driver.gem can be used as an alias to install benchmark\_driver.gem

# v0.10.16

- `command_stdout` runner uses YAML's dirname as `working_directory` by default

# v0.10.15

- Make `Benchmark.driver` take `repeat_count:` keyword argument

# v0.10.14

- Fix a bug that large time is shown as better in time runner

# v0.10.13

- Add `x.output` to specify output plugin to Ruby interface
  - You can still use `Benchmark.driver(output: xxx)` form too

# v0.10.12

- Fix some typo in help
- Add dynamic require for convenience to implement output plugins

# v0.10.11

- Add `:required_ruby_option` parameter in YAML format

# v0.10.10

- Add `BenchmarkDriver::Config::Executable#description` method to return `ruby -v` result for output plugins.

# v0.10.9

- Add `x.rbenv`, `x.loop_count`, `x.verbose` supports to Ruby interface

# v0.10.8

- In `command_stdout`, `$RBENV_VERSION` is no longer passed to --rbenv option because it has no effect for rbenv
- Instead, now dirname of executable path is prefixed to $PATH in `command_stdout`

# v0.10.7

- Pass `$RBENV_VERSION` for `command_stdout` runner with --rbenv option

# v0.10.6

- Fix TypeError on Ruby <= 2.3

# v0.10.5

- Run runners with Bundler's clean env

# v0.10.4

- Fix frozen string error when parsing multiple jobs

# v0.10.3

- Allow specifying name in `--rbenv`
- Don't print stderr in "command\_stdout" runner

# v0.10.2

- Optionalize `working_directory` of "command\_stdout" runner

# v0.10.1

- Add "command\_stdout" runner to plug in existing benchmark
- Explicitly bump supported Ruby version to >= 2.2
  - v0.10.0 actually does not work with 2.1
  - You can still benchmark Ruby 2.0, 2.1 by --executable, but you need to use newer Ruby for driver

# v0.10.0

- Add "record" output and "recorded" runner
  - You can record metrics to yaml and change how to output later
- Change output interface to set metrics\_type
  - Now runner needs to call `output#metrics_type=`

# v0.9.2

- Add `--verbose` option
  - `--verbose 1` shows `ruby -v` for each executable
  - `--verbose 2` shows executed scripts

# v0.9.1

- Fix memory runner bug that actually doesn't run the benchmarked script
- Add once runner to test benchmark script in a short time

# v0.9.0

- The concept of runner is renewed
  - Now it's for specifying metrics like ips, time, memory usage
  - Old runners (:call and :eval) are no longer supported. :exec only.
     - So Ruby interface can't take Proc
  - YAML can have arbitrary format depending on the runner
- `--compare` option is dropped and changed to `--output compare`
- `--dir` option is dropped for now

# v0.8.6

- Automatically require `benchmark/output/foo` when `-o foo` is specified

# v0.8.5

- Show time per iteration for ips output
  - Show clocks/i too when it's < 1000 clocks/i
- In ips output, 'B' unit (10^9) is changed to 'G'

# v0.8.4

- Add `loop_count` option to Ruby interface

# v0.8.3

- Make benchmark\_driver runnable when Bundler is not installed

# v0.8.2

- Fix bug on showing error message in `benchmark-driver` command

# v0.8.1

- Fix internal implementation of Eval runner
  - Now this can accept class definition in prelude

# v0.8.0

- Force using :exec runner for YAML interface
- Fix bug that executables become empty

# v0.7.2

- Respect ignored output option in Ruby interface

# v0.7.1

- Add `x.rbenv` to Ruby interface
- Add `x.bundler` to Ruby interface

# v0.7.0

- Change Ruby interface for specifying prelude and script
  - #prelude= is renamed to #prelude
  - `script:` is no longer a keyword argument
- Add Eval runner and it's made default for Ruby interface when script is String

# v0.6.2

- Resurrect support of Ruby interface dropped at v0.6.0
- Invalidate wrong configuration
- Decide runner type automatically for Ruby interface

# v0.6.1

- Support markdown output

# v0.6.0

- Drop support of Ruby interface
- Drop support of specifying runner, output options on YAML definition
- Allow specifying output type on CLI
- Run multiple benchmark files at once, instead of sequentially executing them

# v0.5.1

- Fix a bug that fails to run multiple Ruby binaries when multiple YAML files are specified

# v0.5.0

- Automatic bundle install for each Ruby executable on `--bundler` or `--bundle`
- CLI error handling is improved for empty/invalid arguments

# v0.4.5

- Allow specifying arguments for ruby executables

# v0.4.4

- Add `--bundler` option to run benchmark with fixed gems

# v0.4.3

- Add `--filter` option to run only specified benchmarks

# v0.4.2

- Exec runner uses `Bundler.with_clean_env`

# v0.4.1

- Increase the number of pasted script in one loop: 50 -> 1000
- Add `--dir` option to override `__dir__`

# v0.4.0

- **Full scratch**: v0.1...v0.3 has no relationship with v0.4
  - Plugin support for runner, output
  - Add initial limited Ruby interface in addition to previous YAML input
     - Add new `call` runner for Ruby and `exec` runner for existing functionality
  - Support repeating multiple times and using the best result
  - Add `compare!` switching
  - Gradual loop time estimation for specific duration
  - Real-time incremental output during benchmark execution
  - Paste the same script 50 times in one loop

# v0.3.0

- Rename `benchmark_driver` command to `benchmark-driver`
- Internally use `Benchmark::Driver` namespace instead of `BenchmarkDriver`

# v0.2.4

- Allow specifying multiple rbenv executables at once

# v0.2.3

- Add `--rbenv` option to specify executables in rbenv

# v0.2.2

- Fix loop count option bug

# v0.2.1

- Stop using `i` for wrapper script for loop
- Fix IPS option bug by @t8m8

# v0.2.0

- Allow specifying loop count

# v0.1.0

- Add `benchmark_driver` command that takes YAML input
  - Runnable with multiple Ruby binaries
  - Show actual time
  - IPS reporter support
  - Prelude and multiple benchmark scripts in one YAML
