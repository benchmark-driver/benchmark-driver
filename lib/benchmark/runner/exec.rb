require 'tempfile'
require 'shellwords'
require 'benchmark/driver/benchmark_result'
require 'benchmark/driver/duration_runner'
require 'benchmark/driver/error'
require 'benchmark/driver/time'

# Run benchmark by executing another Ruby process.
#
# Multiple Ruby binaries: o
# Memory output: o
class Benchmark::Runner::Exec
  WARMUP_DURATION    = 1
  BENCHMARK_DURATION = 4
  GUESS_TIMES = [1, 1_000, 1_000_000, 10_000_000, 100_000_000]

  # @param [Benchmark::Driver::Configuration::RunnerOptions] options
  # @param [Benchmark::Output::*] output - Object that responds to methods used in this class
  def initialize(options, output:)
    @options = options
    @output  = output
  end

  # @param [Benchmark::Driver::Configuration] config
  def run(config)
    validate_config(config)

    if config.jobs.any? { |job| job.loop_count.nil? }
      iters_by_job = run_warmup(config.jobs)
    end

    @output.start_running

    config.jobs.each do |job|
      @output.running(job.name)

      @options.executables.each do |executable|
        runner = build_runner(executable.path)

        if job.loop_count
          duration = runner.call(job, job.loop_count)
          result = Benchmark::Driver::BenchmarkResult.new(job, duration, job.loop_count)
        else
          result = Benchmark::Driver::DurationRunner.new(job).run(
            seconds:    BENCHMARK_DURATION,
            unit_iters: iters_by_job.fetch(job),
            runner:     runner,
          )
        end

        if result.duration < 0
          raise Benchmark::Driver::ExecutionTimeTooShort.new(job, result.iterations)
        end
        @output.benchmark_stats(result)
      end
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
      next if job.loop_count
      @output.warming(job.name)

      result = Benchmark::Driver::DurationRunner.new(job).run(
        seconds:    WARMUP_DURATION,
        unit_iters: guess_ip100ms(job),
        runner:     build_runner, # TODO: should use executables instead of RbConfig.ruby
      )
      iters_by_job[job] = result.ips.ceil

      if result.duration < 0
        raise Benchmark::Driver::ExecutionTimeTooShort.new(job, result.iterations)
      end
      @output.warmup_stats(result)
    end

    iters_by_job
  end

  # @param [Benchmark::Driver::Configuration::Job] job
  def guess_ip100ms(job)
    ip100ms = 0
    GUESS_TIMES.each do |times|
      seconds = build_runner.call(job, times) # TODO: should use executables instead of RbConfig.ruby
      ip100ms = (times.to_f / (seconds * 10.0)).ceil # ceil for times=1
      if 0.2 < seconds # 200ms theshold
        return ip100ms
      end
    end
    if ip100ms < 0
      raise Benchmark::Driver::ExecutionTimeTooShort.new(job, GUESS_TIMES.last)
    end
    ip100ms
  end

  # @param [String] path - Path to Ruby executable
  # @return [Proc] - Lambda to run benchmark
  def build_runner(path = RbConfig.ruby)
    lambda do |job, times|
      benchmark = BenchmarkScript.new(job.prelude, job.script)
      measure_seconds(path, benchmark.full_script(times)) -
        measure_seconds(path, benchmark.overhead_script(times))
    end
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
    BATCH_SIZE = 50

    def overhead_script(times)
      raise ArgumentError.new("Negative times: #{times}") if times < 0
      <<-RUBY
#{prelude}
__benchmark_driver_i = 0
while __benchmark_driver_i < #{times / BATCH_SIZE}
  __benchmark_driver_i += 1
end
      RUBY
    end

    def full_script(times)
      raise ArgumentError.new("Negative times: #{times}") if times < 0
      <<-RUBY
#{prelude}
__benchmark_driver_i = 0
while __benchmark_driver_i < #{times / BATCH_SIZE}
  __benchmark_driver_i += 1
  #{"#{script};" * BATCH_SIZE}
end
#{"#{script};" * (times % BATCH_SIZE)}
      RUBY
    end
  end
end
