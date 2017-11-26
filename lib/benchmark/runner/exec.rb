require 'tempfile'
require 'shellwords'
require 'benchmark/driver/benchmark_result'
require 'benchmark/driver/duration_runner'
require 'benchmark/driver/time'

# Run benchmark by executing another Ruby process.
#
# Multiple Ruby binaries: o
# Memory profiler: o
class Benchmark::Runner::Exec
  WARMUP_DURATION    = 1
  BENCHMARK_DURATION = 4

  # @param [Benchmark::Driver::Configuration::RunnerOptions] options
  # @param [Benchmark::Output::*] output - Object that responds to methods used in this class
  # @param [Benchmark::Profiler::*] profiler - Object that responds to methods used in this class
  def initialize(options, output:, profiler:)
    @options  = options
    @output   = output
    @profiler = profiler # TODO: use this
  end

  # @param [Benchmark::Driver::Configuration] config
  def run(config)
    validate_config(config)

    unless @options.loop_count
      iters_by_job = run_warmup(config.jobs)
    end

    @output.start_running

    config.jobs.each do |job|
      @output.running(job.name)

      if @options.loop_count
        duration = script_only_seconds(job, @options.loop_count)
        result = Benchmark::Driver::BenchmarkResult.new(job, duration, @options.loop_count)
      else
        result = Benchmark::Driver::DurationRunner.new(job).run(
          seconds:    BENCHMARK_DURATION,
          unit_iters: iters_by_job.fetch(job),
          runner:     method(:script_only_seconds),
        )
      end

      @output.benchmark_stats(result)
    end

    @output.finish
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
  # @return [Hash{ Benchmark::Driver::Configuration::Job => Integer }] iters_by_job
  def run_warmup(jobs)
    @output.start_warming
    iters_by_job = {}

    jobs.each do |job|
      @output.warming(job.name)

      result = Benchmark::Driver::DurationRunner.new(job).run(
        seconds:    WARMUP_DURATION,
        unit_iters: guess_ip100ms(job),
        runner:     method(:script_only_seconds),
      )
      iters_by_job[job] = result.ips.ceil

      @output.warmup_stats(result)
    end

    iters_by_job
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
