require 'benchmark_driver/struct'

module BenchmarkDriver
  # All CLI options
  Config = ::BenchmarkDriver::Struct.new(
    :runner_type,  # @param [String]
    :output_type,  # @param [String]
    :paths,        # @param [Array<String>]
    :executables,  # @param [Array<BenchmarkDriver::Config::Executable>]
    :filters,      # @param [Array<Regexp>]
    :repeat_count, # @param [Integer]
    :run_duration, # @param [Integer]
    :verbose,      # @param [Integer]
    defaults: {
      runner_type: 'ips',
      output_type: 'compare',
      filters: [],
      repeat_count: 1,
      run_duration: 3,
      verbose: 0,
    },
  )

  # Subset of FullConfig passed to JobRunner
  Config::RunnerConfig = ::BenchmarkDriver::Struct.new(
    :executables,  # @param [Array<BenchmarkDriver::Config::Executable>]
    :repeat_count, # @param [Integer]
    :run_duration, # @param [Integer]
    :verbose,      # @param [Integer]
  )

  Config::Executable = ::BenchmarkDriver::Struct.new(
    :name,    # @param [String]
    :command, # @param [Array<String>]
  )
  Config.defaults[:executables] = [
    BenchmarkDriver::Config::Executable.new(name: RUBY_VERSION, command: [RbConfig.ruby]),
  ]
end
