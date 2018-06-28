require 'benchmark_driver/struct'
require 'benchmark_driver/metric'
require 'tempfile'
require 'shellwords'

# Run only once, for testing
class BenchmarkDriver::Runner::Recorded
  # JobParser returns this, `BenchmarkDriver::Runner.runner_for` searches "*::Job"
  Job = ::BenchmarkDriver::Struct.new(
    :name,              # @param [String] name - This is mandatory for all runner
    :job,               # @param [BenchmarkDriver::Runner::*::Job]
    :warmup_metrics,    # @param [Hash]
    :benchmark_metrics, # @param [Hash]
    :metrics_type,      # @param [BenchmarkDriver::Metrics::Type]
  )
  # Dynamically fetched and used by `BenchmarkDriver::JobParser.parse`
  class << JobParser = Module.new
    # @param [Hash] metrics_by_job
    # @param [BenchmarkDriver::Metrics::Type] metrics_type
    def parse(metrics_by_job:, metrics_type:)
      metrics_by_job.map do |job, metrics_hash|
        Job.new(
          name: job.name,
          job: job,
          warmup_metrics: metrics_hash.fetch(:warmup, []),
          benchmark_metrics: metrics_hash.fetch(:benchmark),
          metrics_type: metrics_type,
        )
      end
    end
  end

  # @param [BenchmarkDriver::Config::RunnerConfig] config
  # @param [BenchmarkDriver::Output::*] output
  def initialize(config:, output:)
    @config = config
    @output = output
  end

  # This method is dynamically called by `BenchmarkDriver::JobRunner.run`
  # @param [Array<BenchmarkDriver::Default::Job>] jobs
  def run(records)
    @output.metrics_type = records.first.metrics_type

    records.each do |record|
      unless record.warmup_metrics.empty?
        # TODO:
      end
    end

    @output.with_benchmark do
      records.each do |record|
        @output.with_job(record.job) do
          record.benchmark_metrics.each do |metrics|
            @output.report(metrics)
          end
        end
      end
    end
  end
end
