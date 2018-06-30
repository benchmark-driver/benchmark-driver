require 'benchmark_driver/struct'
require 'benchmark_driver/metric'
require 'tempfile'
require 'shellwords'

# Run only once, for testing
class BenchmarkDriver::Runner::Recorded
  # JobParser returns this, `BenchmarkDriver::Runner.runner_for` searches "*::Job"
  Job = ::BenchmarkDriver::Struct.new(
    :name,              # @param [String] name - This is mandatory for all runner
    :warmup_results,    # @param [Hash{ BenchmarkDriver::Context => Array<BenchmarkDriver::Metric> } }]
    :benchmark_results, # @param [Hash{ BenchmarkDriver::Context => Array<BenchmarkDriver::Metric> } }]
    :metrics,           # @param [Array<BenchmarkDriver::Metric>]
  )
  # Dynamically fetched and used by `BenchmarkDriver::JobParser.parse`
  class << JobParser = Module.new
    # @param [Hash{ String => Hash{ TrueClass,FalseClass => Hash{ BenchmarkDriver::Context => Hash{ BenchmarkDriver::Metric => Float } } } }] job_warmup_context_metric_value
    # @param [BenchmarkDriver::Metrics::Type] metrics
    def parse(job_warmup_context_metric_value:, metrics:)
      job_warmup_context_metric_value.map do |job_name, warmup_context_values|
        Job.new(
          name: job_name,
          warmup_results: warmup_context_values.fetch(true, {}),
          benchmark_results: warmup_context_values.fetch(false, {}),
          metrics: metrics,
        )
      end
    end
  end

  # @param [BenchmarkDriver::Config::RunnerConfig] config
  # @param [BenchmarkDriver::Output] output
  def initialize(config:, output:)
    @config = config
    @output = output
  end

  # This method is dynamically called by `BenchmarkDriver::JobRunner.run`
  # @param [Array<BenchmarkDriver::Runner::Recorded::Job>] record
  def run(records)
    @output.metrics = records.first.metrics

    records.each do |record|
      unless record.warmup_results.empty?
        # TODO:
      end
    end

    @output.with_benchmark do
      records.each do |record|
        @output.with_job(name: record.name) do
          record.benchmark_results.each do |context, metric_values|
            @output.with_context(
              name: context.name,
              executable: context.executable,
              duration: context.duration,
              loop_count: context.loop_count,
            ) do
              metric_values.each do |metric, value|
                @output.report(value: value, metric: metric)
              end
            end
          end
        end
      end
    end
  end
end
