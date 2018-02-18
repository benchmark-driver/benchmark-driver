require 'benchmark_driver/struct'
require 'benchmark_driver/metrics'
require 'benchmark_driver/default_job'
require 'benchmark_driver/default_job_parser'
require 'tempfile'
require 'shellwords'

class BenchmarkDriver::Runner::Ips
  Job = Class.new(BenchmarkDriver::DefaultJob)
  JobParser = BenchmarkDriver::DefaultJobParser.for(Job)

  METRICS_TYPE = BenchmarkDriver::Metrics::Type.new(unit: 'i/s')

  # @param [BenchmarkDriver::Config::RunnerConfig] config
  # @param [BenchmarkDriver::Output::*] output
  def initialize(config:, output:)
    @config = config
    @output = output
  end

  # This method is dynamically called by `BenchmarkDriver::JobRunner.run`
  # @param [Array<BenchmarkDriver::Default::Job>] jobs
  def run(jobs)
    @output.with_benchmark(METRICS_TYPE) do
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

  # @param [Array<BenchmarkDriver::Default::Job>] jobs
  # @param [Array<BenchmarkDriver::Config::Executable>] exec
  # @return [BenchmarkDriver::Metrics]
  def run_benchmark(job, exec:)
    benchmark = BenchmarkScript.new(
      before:     job.before,
      script:     job.script,
      after:      job.after,
      loop_count: job.loop_count,
    )

    duration = Tempfile.open(['benchmark_driver-', '.txt']) do |f|
      with_script(benchmark.render(result: f.path)) do |path|
        execute(*exec.command, path)
      end
      Float(f.read)
    end

    BenchmarkDriver::Metrics.new(value: job.loop_count.to_f / duration, executable: exec)
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

result = (__benchmark_driver_script_finish - __benchmark_driver_script_start) -
  (__benchmark_driver_empty_finish - __benchmark_driver_empty_start)
File.write(#{result.dump}, result)
      RUBY
    end

    private

    def while_loop(content, times)
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
