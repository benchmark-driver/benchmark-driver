require 'bundler'
require 'tempfile'
require 'shellwords'
require 'benchmark/driver/benchmark_result'
require 'benchmark/driver/duration_runner'
require 'benchmark/driver/repeatable_runner'
require 'benchmark/driver/error'
require 'benchmark/driver/time'

# Run benchmark by executing another Ruby process.
#
# Multiple Ruby binaries: o
# Memory output: o
class Benchmark::Runner::Exec
  # This class can provide fields in `Benchmark::Driver::BenchmarkResult` if required by output plugins.
  SUPPORTED_FIELDS = [:real, :max_rss]

  WARMUP_DURATION    = 1
  BENCHMARK_DURATION = 4
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

      @options.executables.each do |executable|
        result = run_benchmark(job, executable)
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

  # @param [Benchmark::Driver::Configuration::Job] job
  # @param [Benchmark::Driver::Configuration::Executable] executable
  def run_benchmark(job, executable)
    fields = @output.class::REQUIRED_FIELDS
    if fields == [:real]
      Benchmark::Driver::RepeatableRunner.new(job).run(
        runner: build_runner(executable.path),
        repeat_count: @options.repeat_count,
      ).tap do |result|
        if result.real < 0
          raise Benchmark::Driver::ExecutionTimeTooShort.new(job, result.iterations)
        end
      end
    elsif fields == [:max_rss] # TODO: we can also capture other metrics with /usr/bin/time
      raise '/usr/bin/time is not available' unless File.exist?('/usr/bin/time')

      script = BenchmarkScript.new(job.prelude, job.script).full_script(job.loop_count)
      with_file(script) do |script_path|
        out = Bundler.with_clean_env { IO.popen(['/usr/bin/time', executable.path, script_path], err: [:child, :out], &:read) }
        match_data = /^(?<user>\d+.\d+)user\s+(?<system>\d+.\d+)system\s+(?<elapsed1>\d+):(?<elapsed2>\d+.\d+)elapsed.+\([^\s]+\s+(?<maxresident>\d+)maxresident\)k$/.match(out)
        raise "Unexpected format given from /usr/bin/time:\n#{out}" unless match_data[:maxresident]

        Benchmark::Driver::BenchmarkResult.new(job).tap do |result|
          result.max_rss = Integer(match_data[:maxresident])
        end
      end
    else
      raise "Unexpected REQUIRED_FIELDS for #{self.class.name}: #{fields.inspect}"
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
        runner:     build_runner, # TODO: should use executables instead of RbConfig.ruby
      )
      job.guessed_count = (result.ips.to_f * BENCHMARK_DURATION).to_i

      if result.duration < 0
        raise Benchmark::Driver::ExecutionTimeTooShort.new(job, result.iterations)
      end
      @output.warmup_stats(result)
    end
  end

  # @param [Benchmark::Driver::Configuration::Job] job
  def guess_ip100ms(job)
    ip100ms = 0
    GUESS_TIMES.each do |times|
      seconds = build_runner.call(job, times) # TODO: should use executables instead of RbConfig.ruby
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

  # @param [String] path - Path to Ruby executable
  # @return [Proc] - Lambda to run benchmark
  def build_runner(path = RbConfig.ruby)
    lambda do |job, times|
      benchmark = BenchmarkScript.new(job.prelude, job.script)
      measure_seconds(path, benchmark.full_script(times)) -
        measure_seconds(path, benchmark.overhead_script(times))
    end
  end

  def with_file(content, &block)
    Tempfile.create(File.basename(__FILE__)) do |f|
      f.write(content)
      f.close
      block.call(f.path)
    end
  end

  def measure_seconds(ruby, script)
    with_file(script) do |path|
      cmd = [ruby, path].shelljoin

      Bundler.with_clean_env do
        before = Benchmark::Driver::Time.now
        system(cmd, out: File::NULL)
        after = Benchmark::Driver::Time.now

        after.to_f - before.to_f
      end
    end
  end

  class BenchmarkScript < Struct.new(:prelude, :script)
    BATCH_SIZE = 1000

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
