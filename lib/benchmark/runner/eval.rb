require 'benchmark/driver/benchmark_result'
require 'benchmark/driver/duration_runner'
require 'benchmark/driver/repeatable_runner'
require 'benchmark/driver/time'

# Run benchmark by calling compiled script on running ruby.
#
# Multiple Ruby binaries: x
# Memory output: x
class Benchmark::Runner::Eval
  # This class can provide fields in `Benchmark::Driver::BenchmarkResult` if required by output plugins.
  SUPPORTED_FIELDS = [:real]

  WARMUP_DURATION    = 2
  BENCHMARK_DURATION = 5
  GUESS_TIMES = [1, 1_000, 1_000_000, 10_000_000, 100_000_000]
  GUESS_THRESHOLD = 0.4 # 400ms

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
      run_warmup(config.jobs)
    end

    @output.start_running

    config.jobs.each do |job|
      @output.running(job.name)

      result = Benchmark::Driver::RepeatableRunner.new(job).run(
        runner: method(:eval_times),
        repeat_count: @options.repeat_count,
      )

      @output.benchmark_stats(result)
    end

    @output.finish
  end

  private

  def validate_config(config)
    if config.runner_options.executables_specified?
      raise ArgumentError.new("#{self.class.name} can't run other Ruby executables")
    end

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

    jobs.each do |job|
      next if job.loop_count
      @output.warming(job.name)

      result = Benchmark::Driver::DurationRunner.new(job).run(
        seconds:    WARMUP_DURATION,
        unit_iters: guess_ip100ms(job),
        runner:     method(:eval_times),
      )
      job.guessed_count = (result.ips.to_f * BENCHMARK_DURATION).to_i

      @output.warmup_stats(result)
    end
  end

  # @param [Benchmark::Driver::Configuration::Job] job
  def guess_ip100ms(job)
    ip100ms = 0
    GUESS_TIMES.each do |times|
      seconds = eval_times(job, times)
      ip100ms = (times.to_f / (seconds * 10.0)).ceil # ceil for times=1
      if GUESS_THRESHOLD < seconds
        return ip100ms
      end
    end
    if ip100ms < 0
      raise Benchmark::Driver::ExecutionTimeTooShort.new(job, GUESS_TIMES.last)
    end
    ip100ms
  end

  def eval_times(job, times)
    benchmark = BenchmarkScript.new(job.prelude, job.script)
    mod = Module.new
    benchmark.compile_overhead!(mod, times)
    benchmark.compile_full_script!(mod, times)

    before = Benchmark::Driver::Time.now
    mod.overhead
    after = Benchmark::Driver::Time.now
    overhead_duration = after.to_f - before.to_f

    before = Benchmark::Driver::Time.now
    mod.full_script
    after = Benchmark::Driver::Time.now
    full_script_duration = after.to_f - before.to_f

    full_script_duration - overhead_duration
  end

  class BenchmarkScript < Struct.new(:prelude, :script)
    BATCH_SIZE = 1000

    def compile_overhead!(mod, times)
      raise ArgumentError.new("Negative times: #{times}") if times < 0
      mod.module_eval(<<-RUBY)
def self.overhead
  #{prelude}
  __benchmark_driver_i = 0
  while __benchmark_driver_i < #{times / BATCH_SIZE}
    __benchmark_driver_i += 1
  end
end
      RUBY
    end

    def compile_full_script!(mod, times)
      raise ArgumentError.new("Negative times: #{times}") if times < 0
      mod.module_eval(<<-RUBY)
def self.full_script
  #{prelude}
  __benchmark_driver_i = 0
  while __benchmark_driver_i < #{times / BATCH_SIZE}
    __benchmark_driver_i += 1
    #{"#{script};" * BATCH_SIZE}
  end
  #{"#{script};" * (times % BATCH_SIZE)}
end
      RUBY
    end
  end
end
