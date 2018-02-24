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
