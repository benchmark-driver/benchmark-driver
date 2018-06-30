require 'forwardable'

module BenchmarkDriver
  # BenchmarkDriver::Runner::* --> BenchmarkDriver::Output --> BenchmarkDriver::Output::*
  #
  # This is interface between runner plugin and output plugin, so that they can be loosely
  # coupled and to simplify implementation of both runner and output.
  #
  # Runner should call its interface in the following manner:
  #   with_warmup
  #     with_job(name:)
  #       with_context(name:, executable:, duration: nil, loop_count: nil)
  #         report(value:)
  #   with_benchmark
  #     with_job(name:)
  #       with_context(name:, executable:, duration: nil, loop_count: nil)
  #         report(value:)
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

    def_delegators :@output, :metrics_type=, :with_warmup, :with_benchmark

    # @param [String]
    def with_job(name:, &block)
      job = BenchmarkDriver::Job.new(name: name)
      @output.with_job(job) do
        block.call
      end
    end

    # @param [String]
    # @param [BenchmarkDriver::Config::Executable]
    def with_context(name:, executable:, duration: nil, loop_count: nil, &block)
      context = BenchmarkDriver::Context.new(
        name: name, executable: executable, duration: duration, loop_count: loop_count,
      )
      @output.with_context(context) do
        block.call
      end
    end

    # @param [Float] value
    # @param [Float,nil] duration (optional)
    def report(value:)
      metric = Metrics.new(value: value)
      @output.report(metric)
    end
  end
end
