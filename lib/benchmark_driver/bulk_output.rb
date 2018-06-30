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
    attr_writer :metrics

    # @param [Array<String>] job_names
    # @param [Array<String>] context_names
    def initialize(job_names:, context_names:)
      # noop
    end

    # The main API you need to override if you make a class inherit `BenchmarkDriver::BulkOutput`.
    # @param [Hash{ BenchmarkDriver::Job => Hash{ BenchmarkDriver::Context => { BenchmarkDriver::Metric => Float } } }] result
    # @param [Array<BenchmarkDriver::Metric>] metrics
    def bulk_output(result:, metrics:)
      raise NotImplementedError.new("#{self.class} must override #bulk_output")
    end

    def with_warmup(&block)
      block.call # noop
    end

    def with_benchmark(&block)
      @result = Hash.new do |h1, job|
        h1[job] = Hash.new do |h2, context|
          h2[context] = {}
        end
      end
      result = block.call
      bulk_output(result: @result, metrics: @metrics)
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

    # @param [Float] value
    # @param [BenchmarkDriver::Metric] metic
    def report(value:, metric:)
      @result[@job][@context][metric] = value
    end
  end
end
