require 'benchmark/driver/benchmark_result'
require 'benchmark/driver/job_runner'
require 'benchmark/driver/time'

# Run benchmark by calling #call on running ruby.
#
# Multiple Ruby binaries: x
# Memory profiler: x
class Benchmark::Runner::Call
  WARMUP_DURATION    = 2
  BENCHMARK_DURATION = 5

  # @param [Benchmark::Output::*] output - Object that responds to methods used in this class
  def initialize(output)
    @output = output
  end

  # @param [Benchmark::Driver::Configuration] config
  # @param [Benchmark::Profiler::*] profiler - Object that responds to methods used in this class
  def run(config, profiler:)
    validate_config(config)

    warmups = run_warmup(config.jobs)
    run_benchmark(warmups)
  end

  private

  def validate_config(config)
    config.jobs.each do |job|
      unless job.script.respond_to?(:call)
        raise NotImplementedError.new(
          "#{self.class.name} only accepts objects that respond to :call, but got #{job.script.inspect}"
        )
      end
    end
  end

  # @param [Array<Benchmark::Driver::Configuration::Job>] jobs
  # @return [Array<Benchmark::Driver::BenchmarkResult>]
  def run_warmup(jobs)
    @output.start_warming

    jobs.map do |job|
      @output.warming(job.name)

      result = Benchmark::Driver::JobRunner.new(job).run(
        seconds:    WARMUP_DURATION,
        unit_iters: 1,
        runner:     method(:call_times),
      )

      @output.warmup_stats(result)
      result
    end
  end

  # @param [Array<Benchmark::Driver::BenchmarkResult>] warmups
  def run_benchmark(warmups)
    @output.start_running

    warmups.each do |warmup|
      @output.running(warmup.job.name)

      result = Benchmark::Driver::JobRunner.new(warmup.job).run(
        seconds:    BENCHMARK_DURATION,
        unit_iters: warmup.ip100ms.to_i,
        runner:     method(:call_times),
      )

      @output.benchmark_stats(result)
    end

    @output.finish
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
