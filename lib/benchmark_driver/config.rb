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
    defaults: {
      runner_type: 'default',
      output_type: 'default',
      executables: [],
      filters: [],
      repeat_count: 1,
    },
  )

  # Subset of FullConfig passed to JobRunner
  Config::RunnerConfig = ::BenchmarkDriver::Struct.new(
    :executables,  # @param [Array<BenchmarkDriver::Config::Executable>]
    :repeat_count, # @param [Integer]
  )

  Config::Executable = ::BenchmarkDriver::Struct.new(
    :name,    # @param [String]
    :command, # @param [Array<String>]
  )
end
