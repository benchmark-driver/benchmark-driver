module BenchmarkDriver
  # BenchmarkDriver::Runner::* --> BenchmarkDriver::Output --> BenchmarkDriver::Output::*
  #
  # This is interface between runner plugin and output plugin, so that they can be loosely
  # coupled and to simplify implementation of both runner and output.
  #
  # Runner should call its interface in the following manner:
  #   metrics=
  #   with_warmup
  #     with_job(name:)
  #       with_context(name:, executable:, gems:)
  #         report(values:, duration: nil, loop_count: nil, environment: {})
  #   with_benchmark
  #     with_job(name:)
  #       with_context(name:, executable:, gems:)
  #         report(values:, duration: nil, loop_count: nil, environment: {})
  class Output
    require 'benchmark_driver/output/compare'
    require 'benchmark_driver/output/markdown'
    require 'benchmark_driver/output/record'
    require 'benchmark_driver/output/simple'

    # @param [String] type
    def self.get(type)
      if type.include?(':')
        raise ArgumentError.new("Output type '#{type}' cannot contain ':'")
      end

      require "benchmark_driver/output/#{type}" # for plugin
      camelized = type.split('_').map(&:capitalize).join
      ::BenchmarkDriver::Output.const_get(camelized, false)
    end

    # BenchmarkDriver::Output is pluggable.
    # Create `BenchmarkDriver::Output::Foo` as benchmark_dirver-output-foo.gem and specify `-o foo`.
    #
    # @param [String] type
    # @param [Array<BenchmarkDriver::Metric>] metrics
    # @param [Array<BenchmarkDriver::Job>] jobs
    # @param [Array<BenchmarkDriver::Context>] contexts
    def initialize(type:, metrics:, jobs:, contexts:)
      @output = ::BenchmarkDriver::Output.get(type).new(
        metrics: metrics,
        jobs: jobs,
        contexts: contexts,
      )
    end

    # @param [Array<BenchmarkDriver::Metric>] metrics
    def metrics=(metrics)
      @output.metrics = metrics
    end

    def with_warmup(&block)
      @output.with_warmup(&block)
    end

    def with_benchmark(&block)
      @output.with_benchmark(&block)
    end

    # @param [String] name
    def with_job(name:, &block)
      job = BenchmarkDriver::Job.new(name: name)
      @output.with_job(job) do
        block.call
      end
    end

    # @param [String] name
    # @param [BenchmarkDriver::Config::Executable] executable
    # @param [Hash{ String => String}] gems
    def with_context(name:, executable:, gems: {}, prelude: '', &block)
      context = BenchmarkDriver::Context.new(name: name, executable: executable, gems: gems, prelude: prelude)
      @output.with_context(context) do
        block.call
      end
    end

    # @param [Hash{ BenchmarkDriver::Metric => Float }] values
    # @param [Hash{ BenchmarkDriver::Metric => [Float] },nil] values
    # @param [BenchmarkDriver::Metric] metic
    def report(values:, all_values: nil, duration: nil, loop_count: nil, environment: {})
      result = BenchmarkDriver::Result.new(
        values: values,
        all_values: all_values,
        duration: duration,
        loop_count: loop_count,
        environment: environment,
      )
      @output.report(result)
    end
  end
end
