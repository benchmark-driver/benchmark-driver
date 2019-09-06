module BenchmarkDriver
  # This is API for your casual output plugin and NOT internally used by BenchmarkDriver.
  #
  # By fully utilizing with_*/report APIs, you can implement streaming-output plugins.
  # See also: lib/benchmark_driver/output.rb (this class's instance will be `@output`)
  # But using these APIs can be difficult because the API is not stable yet and it's hard
  # to deal with the complex state machine.
  #
  # If you don't need to output results in a streaming manner, you can create an output
  # plugin class that inherits `BenchmarkDriver::BulkOutput`, which requires to override
  # only `#bulk_output` that takes all inputs at once.
  class BulkOutput
    # @param [Array<BenchmarkDriver::Metric>] metrics
    # @param [Array<BenchmarkDriver::Job>] jobs
    # @param [Array<BenchmarkDriver::Context>] contexts
    # @param [Hash{ Symbol => Object }] options
    def initialize(metrics:, jobs:, contexts:, options: {})
      @metrics = metrics
    end

    # The main API you need to override if you make a class inherit `BenchmarkDriver::BulkOutput`.
    # @param [Hash{ BenchmarkDriver::Job => Hash{ BenchmarkDriver::Context => BenchmarkDriver::Result } }] job_context_result
    # @param [Array<BenchmarkDriver::Metric>] metrics
    def bulk_output(job_context_result:, metrics:)
      raise NotImplementedError.new("#{self.class} must override #bulk_output")
    end

    def with_warmup(&block)
      block.call # noop
    end

    def with_benchmark(&block)
      @job_context_result = Hash.new do |hash, job|
        hash[job] = {}
      end
      result = block.call
      bulk_output(job_context_result: @job_context_result, metrics: @metrics)
      result
    end

    # @param [BenchmarkDriver::Job] job
    def with_job(job, &block)
      @job = job
      block.call
    end

    # @param [BenchmarkDriver::Context] context
    def with_context(context, &block)
      @context = context
      block.call
    end

    # @param [BenchmarkDriver::Result] result
    def report(result)
      if defined?(@job_context_result)
        @job_context_result[@job][@context] = result
      end
    end
  end
end
