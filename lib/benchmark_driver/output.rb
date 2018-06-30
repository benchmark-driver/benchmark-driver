require 'forwardable'

module BenchmarkDriver
  # This is interface between runner plugin and output plugin, so that they can be loosely
  # coupled and to simplify runner implementation by wrapping thins here instead.
  #
  # BenchmarkDriver::Runner::* --> BenchmarkDriver::Output --> BenchmarkDriver::Output::*
  class Output
    require 'benchmark_driver/output/compare'
    require 'benchmark_driver/output/markdown'
    require 'benchmark_driver/output/record'
    require 'benchmark_driver/output/simple'

    extend Forwardable

    # BenchmarkDriver::Output is pluggable.
    # Create `BenchmarkDriver::Output::Foo` as benchmark_dirver-output-foo.gem and specify `-o foo`.
    #
    # @param [String] type
    def initialize(type:, jobs:, executables:)
      if type.include?(':')
        raise ArgumentError.new("Output type '#{type}' cannot contain ':'")
      end

      require "benchmark_driver/output/#{type}" # for plugin
      camelized = type.split('_').map(&:capitalize).join

      @output = ::BenchmarkDriver::Output.const_get(camelized, false).new(
        jobs: jobs,
        executables: executables,
      )
    end

    def_delegators :@output, :metrics_type=, :with_warmup, :with_benchmark, :with_job, :report
  end
end
