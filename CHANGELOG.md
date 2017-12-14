# v0.5.0

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
