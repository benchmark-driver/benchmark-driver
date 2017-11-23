require 'benchmark/driver/benchmark_result'
require 'benchmark/driver/time'

# Run benchmark with calling #call on running ruby.
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
          "Benchmark::Runner::Call only accepts objects that respond to :call, but got #{job.script.inspect}"
        )
      end
    end
  end

  # @param [Array<Benchmark::Driver::Configuration::Job>] config.jobs
  # @return [Array<Benchmark::Driver::BenchmarkResult>]
  def run_warmup(jobs)
    @output.start_warming

    jobs.map do |job|
      @output.warming(job.name)
      iterations = 0

      before = Benchmark::Driver::Time.now
      warmup_until = before + WARMUP_DURATION
      while Benchmark::Driver::Time.now < warmup_until
        job.script.call
        iterations += 1
      end
      after = Benchmark::Driver::Time.now

      duration = after.to_f - before.to_f
      Benchmark::Driver::BenchmarkResult.new(job, duration, iterations).tap do |result|
        @output.warmup_stats(result)
      end
    end
  end

  # @param [Array<Benchmark::Driver::BenchmarkResult>] warmups
  def run_benchmark(warmups)
    @output.start_running

    warmups.each do |warmup|
      @output.running(warmup.job.name)
      iterations = 0
      duration   = 0.0
      unit_iters = warmup.ip100ms.to_i

      benchmark_until = Benchmark::Driver::Time.now + BENCHMARK_DURATION
      while Benchmark::Driver::Time.now < benchmark_until
        duration   += call_times(warmup.job.script, unit_iters)
        iterations += unit_iters
      end

      result = Benchmark::Driver::BenchmarkResult.new(warmup.job, duration, iterations)
      @output.benchmark_stats(result)
    end

    @output.finish
  end

  def call_times(script, times)
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
