require 'benchmark_driver/struct'

module BenchmarkDriver
  Config = ::BenchmarkDriver::Struct.new(
    :output,       # @param [String] output
    :execs,        # @param [Array<BenchmarkDriver::Config::Executable>]
    :repeat_count, # @param [Integer] repeat_count
    defaults: { execs: [] },
  )

  Config::Executable = ::BenchmarkDriver::Struct.new(
    :name,    # @param [String]
    :command, # @param [Array<String>]
  )
end
