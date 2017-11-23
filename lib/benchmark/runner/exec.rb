require 'tempfile'
require 'shellwords'
require 'benchmark/driver/benchmark_result'
require 'benchmark/driver/time'

# Run benchmark by executing another Ruby process.
#
# Multiple Ruby binaries: o
# Memory profiler: o
class Benchmark::Runner::Exec
  WARMUP_DURATION    = 1
  BENCHMARK_DURATION = 4

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
      unless job.script.is_a?(String)
        raise NotImplementedError.new(
          "#{self.class.name} only accepts String, but got #{job.script.inspect}"
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
      duration   = 0.0
      iterations = 0
      unit_iters = guess_ip100ms(job)

      warmup_until = Benchmark::Driver::Time.now + WARMUP_DURATION
      while Benchmark::Driver::Time.now < warmup_until
        duration += script_only_seconds(job, unit_iters)
        iterations += unit_iters
      end

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
      duration   = 0.0
      iterations = 0
      unit_iters = warmup.ips.ceil

      benchmark_until = Benchmark::Driver::Time.now + BENCHMARK_DURATION
      while Benchmark::Driver::Time.now < benchmark_until
        duration   += script_only_seconds(warmup.job, unit_iters)
        iterations += unit_iters
      end

      result = Benchmark::Driver::BenchmarkResult.new(warmup.job, duration, iterations)
      @output.benchmark_stats(result)
    end

    @output.finish
  end

  # @param [Benchmark::Driver::Configuration::Job] job
  def guess_ip100ms(job)
    ip100ms = 0
    [1, 1_000, 1_000_000, 10_000_000, 100_000_000].each do |times|
      seconds = script_only_seconds(job, times)
      ip100ms = (times.to_f / (seconds * 10.0)).ceil # ceil for times=1
      if 0.2 < seconds # 200ms theshold
        return ip100ms
      end
    end
    ip100ms
  end

  def script_only_seconds(job, times)
    benchmark = BenchmarkScript.new(job.prelude, job.script)
    measure_seconds(RbConfig.ruby, benchmark.full_script(times)) -
      measure_seconds(RbConfig.ruby, benchmark.overhead_script(times))
  end

  def measure_seconds(ruby, script)
    Tempfile.create(File.basename(__FILE__)) do |f|
      f.write(script)
      f.close
      cmd = [ruby, f.path].shelljoin

      before = Benchmark::Driver::Time.now
      system(cmd, out: File::NULL)
      after = Benchmark::Driver::Time.now

      after.to_f - before.to_f
    end
  end

  class BenchmarkScript < Struct.new(:prelude, :script)
    def overhead_script(times)
      <<-RUBY
#{prelude}
__benchmark_driver_i = 0
while __benchmark_driver_i < #{times}
  __benchmark_driver_i += 1
end
      RUBY
    end

    def full_script(times)
      <<-RUBY
#{prelude}
__benchmark_driver_i = 0
while __benchmark_driver_i < #{times}
  __benchmark_driver_i += 1
#{script}
end
      RUBY
    end
  end
end
