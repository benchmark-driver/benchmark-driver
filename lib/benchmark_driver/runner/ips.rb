require 'benchmark_driver/struct'
require 'benchmark_driver/metrics'
require 'benchmark_driver/default_job'
require 'benchmark_driver/default_job_parser'
require 'tempfile'
require 'shellwords'

class BenchmarkDriver::Runner::Ips
  # JobParser returns this, `BenchmarkDriver::Runner.runner_for` searches "*::Job"
  Job = Class.new(BenchmarkDriver::DefaultJob)

  # Dynamically fetched and used by `BenchmarkDriver::JobParser.parse`
  JobParser = BenchmarkDriver::DefaultJobParser.for(Job)

  # Set to `output` by `BenchmarkDriver::Runner.run`
  MetricsType = BenchmarkDriver::Metrics::Type.new(unit: 'i/s')

  # @param [BenchmarkDriver::Config::RunnerConfig] config
  # @param [BenchmarkDriver::Output::*] output
  def initialize(config:, output:)
    @config = config
    @output = output
  end

  # This method is dynamically called by `BenchmarkDriver::JobRunner.run`
  # @param [Array<BenchmarkDriver::Default::Job>] jobs
  def run(jobs)
    if jobs.any? { |job| job.loop_count.nil? }
      @output.with_warmup do
        jobs = jobs.map do |job|
          next job if job.loop_count # skip warmup if loop_count is set

          @output.with_job(job) do
            metrics = run_warmup(job, exec: @config.executables.first)
            @output.report(metrics)
            Job.new(job.to_h.merge(loop_count: 100))
          end
        end
      end
    end

    @output.with_benchmark do
      jobs.each do |job|
        @output.with_job(job) do
          @config.executables.each do |exec|
            @output.report(run_benchmark(job, exec: exec))
          end
        end
      end
    end
  end

  private

  # @param [BenchmarkDriver::Runner::Ips::Job] job - loop_count is nil
  # @param [BenchmarkDriver::Config::Executable] exec
  def run_warmup(job, exec:)
    warmup = WarmupScript.new(
      before:     job.before,
      script:     job.script,
      after:      job.after,
      loop_count: job.loop_count,
    )

    hash = Tempfile.open(['benchmark_driver-', '.rb']) do |f|
      with_script(warmup.render(result: f.path)) do |path|
        execute(*exec.command, path)
      end
      eval(f.read)
    end

    BenchmarkDriver::Metrics.new(
      value: hash.fetch(:loop_count).to_f / hash.fetch(:duration),
      loop_count: hash.fetch(:loop_count),
      executable: exec,
    )
  end

  # @param [BenchmarkDriver::Runner::Ips::Job] job - loop_count is not nil
  # @param [BenchmarkDriver::Config::Executable] exec
  # @return [BenchmarkDriver::Metrics]
  def run_benchmark(job, exec:)
    benchmark = BenchmarkScript.new(
      before:     job.before,
      script:     job.script,
      after:      job.after,
      loop_count: job.loop_count,
    )

    duration = Tempfile.open(['benchmark_driver-', '.rb']) do |f|
      with_script(benchmark.render(result: f.path)) do |path|
        execute(*exec.command, path)
      end
      Float(f.read)
    end

    BenchmarkDriver::Metrics.new(
      value: job.loop_count.to_f / duration,
      loop_count: job.loop_count,
      executable: exec,
    )
  end

  def with_script(script)
    Tempfile.open(['benchmark_driver-', '.rb']) do |f|
      f.puts script
      f.close
      return yield(f.path)
    end
  end

  def execute(*args)
    IO.popen(args, &:read) # handle stdout?
    unless $?.success?
      raise "Failed to execute: #{args.shelljoin} (status: #{$?.exitstatus})"
    end
  end

  WarmupScript = ::BenchmarkDriver::Struct.new(:before, :script, :after, :loop_count) do
    # @param [String] result - A file to write result
    def render(result:)
      <<-RUBY
File.write(#{result.dump}, { duration: 1, loop_count: 1000 })
      RUBY
    end
  end
  private_constant :WarmupScript

  # @param [String] before
  # @param [String] script
  # @param [String] after
  # @param [Integer] loop_count
  BenchmarkScript = ::BenchmarkDriver::Struct.new(:before, :script, :after, :loop_count) do
    # @param [String] result - A file to write result
    def render(result:)
      <<-RUBY
#{before}

if Process.respond_to?(:clock_gettime) # Ruby 2.1+
  __benchmark_driver_empty_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  #{while_loop('', loop_count)}
  __benchmark_driver_empty_finish = Process.clock_gettime(Process::CLOCK_MONOTONIC)
else
  __benchmark_driver_empty_start = Time.now
  #{while_loop('', loop_count)}
  __benchmark_driver_empty_finish = Time.now
end

if Process.respond_to?(:clock_gettime) # Ruby 2.1+
  __benchmark_driver_script_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  #{while_loop(script, loop_count)}
  __benchmark_driver_script_finish = Process.clock_gettime(Process::CLOCK_MONOTONIC)
else
  __benchmark_driver_script_start = Time.now
  #{while_loop(script, loop_count)}
  __benchmark_driver_script_finish = Time.now
end

#{after}

__benchmark_driver_result = __benchmark_driver_script_finish - __benchmark_driver_script_start
if (__benchmark_driver_overhead = __benchmark_driver_empty_finish - __benchmark_driver_empty_start) < __benchmark_driver_result
  # TODO: show something in output
  __benchmark_driver_result -= __benchmark_driver_overhead
end
File.write(#{result.dump}, __benchmark_driver_result.to_s)
      RUBY
    end

    private

    def while_loop(content, times)
      if !times.is_a?(Integer) || times <= 0
        raise ArgumentError.new("Unexpected times: #{times.inspect}")
      end

      # TODO: execute in batch
      <<-RUBY
__benchmark_driver_i = 0
while __benchmark_driver_i < #{times}
  #{content}
  __benchmark_driver_i += 1
end
      RUBY
    end
  end
  private_constant :BenchmarkScript
end
