require 'benchmark/driver/benchmark_result'
require 'benchmark/driver/duration_runner'
require 'benchmark/driver/time'

# Run benchmark by calling #call on running ruby.
#
# Multiple Ruby binaries: x
# Memory output: x
class Benchmark::Runner::Call
  WARMUP_DURATION    = 2
  BENCHMARK_DURATION = 5

  # @param [Benchmark::Driver::Configuration::RunnerOptions] options
  # @param [Benchmark::Output::*] output - Object that responds to methods used in this class
  def initialize(options, output:)
    @options = options
    @output  = output
  end

  # @param [Benchmark::Driver::Configuration] config
  def run(config)
    validate_config(config)

    if config.jobs.any?(&:warmup_needed?)
      iters_by_job = run_warmup(config.jobs)
    end

    @output.start_running

    config.jobs.each do |job|
      @output.running(job.name)

      if job.loop_count
        duration = call_times(job, job.loop_count)
        result = Benchmark::Driver::BenchmarkResult.new(job, duration, job.loop_count)
      else
        result = Benchmark::Driver::DurationRunner.new(job).run(
          seconds:    BENCHMARK_DURATION,
          unit_iters: iters_by_job.fetch(job),
          runner:     method(:call_times),
        )
      end

      @output.benchmark_stats(result)
    end

    @output.finish
  end

  private

  def validate_config(config)
    if config.runner_options.executables_specified?
      raise ArgumentError.new("Benchmark::Runner::Call can't run other Ruby executables")
    end

    config.jobs.each do |job|
      unless job.script.respond_to?(:call)
        raise NotImplementedError.new(
          "#{self.class.name} only accepts objects that respond to :call, but got #{job.script.inspect}"
        )
      end
    end
  end

  # @param [Array<Benchmark::Driver::Configuration::Job>] jobs
  # @return [Hash{ Benchmark::Driver::Configuration::Job => Integer }] iters_by_job
  def run_warmup(jobs)
    @output.start_warming
    iters_by_job = {}

    jobs.each do |job|
      next if job.loop_count
      @output.warming(job.name)

      result = Benchmark::Driver::DurationRunner.new(job).run(
        seconds:    WARMUP_DURATION,
        unit_iters: 1,
        runner:     method(:call_times),
      )
      iters_by_job[job] = result.ip100ms.to_i

      @output.warmup_stats(result)
    end

    iters_by_job
  end

  def call_times(job, times)
    script = job.script
    i = 0

    before = Benchmark::Driver::Time.now
    while i < times
      script.call
      i += 1
    end
    after = Benchmark::Driver::Time.now

    after.to_f - before.to_f
  end
end
