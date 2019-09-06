require 'benchmark_driver/struct'
require 'benchmark_driver/metric'
require 'tempfile'
require 'shellwords'

# Run only once, for testing
class BenchmarkDriver::Runner::Recorded
  # JobParser returns this, `BenchmarkDriver::Runner.runner_for` searches "*::Job"
  Job = ::BenchmarkDriver::Struct.new(
    :name,              # @param [String] name - This is mandatory for all runner
    :metrics,           # @param [Array<BenchmarkDriver::Metric>]
    :warmup_results,    # @param [Hash{ BenchmarkDriver::Context => Array<BenchmarkDriver::Metric> } }]
    :benchmark_results, # @param [Hash{ BenchmarkDriver::Context => Array<BenchmarkDriver::Metric> } }]
    :contexts,          # @param [Array<BenchmarkDriver::Context>]
  )
  # Dynamically fetched and used by `BenchmarkDriver::JobParser.parse`
  class << JobParser = Module.new
    # @param [Hash{ BenchmarkDriver::Job => Hash{ TrueClass,FalseClass => Hash{ BenchmarkDriver::Context => BenchmarkDriver::Result } } }] job_warmup_context_result
    # @param [BenchmarkDriver::Metrics::Type] metrics
    def parse(job_warmup_context_result:, metrics:)
      job_warmup_context_result.map do |job, warmup_context_result|
        Job.new(
          name: job.name,
          warmup_results: warmup_context_result.fetch(true, {}),
          benchmark_results: warmup_context_result.fetch(false, {}),
          metrics: metrics,
          contexts: warmup_context_result.values.map(&:keys).flatten!.tap(&:uniq!),
        )
      end
    end
  end

  # @param [BenchmarkDriver::Config::RunnerConfig] config
  # @param [BenchmarkDriver::Output] output
  # @param [BenchmarkDriver::Context] contexts
  def initialize(config:, output:, contexts:)
    @config = config
    @output = output
    @contexts = contexts
  end

  # This method is dynamically called by `BenchmarkDriver::JobRunner.run`
  # @param [Array<BenchmarkDriver::Runner::Recorded::Job>] record
  def run(records)
    records.each do |record|
      unless record.warmup_results.empty?
        # TODO:
      end
    end

    @output.with_benchmark do
      records.each do |record|
        @output.with_job(name: record.name) do
          record.benchmark_results.each do |context, result|
            @output.with_context(
              name: context.name,
              executable: context.executable,
              gems: context.gems,
              prelude: context.prelude,
            ) do
              @output.report(
                values: result.values,
                all_values: result.all_values,
                duration: result.duration,
                loop_count: result.loop_count,
                environment: result.environment,
              )
            end
          end
        end
      end
    end
  end
end
