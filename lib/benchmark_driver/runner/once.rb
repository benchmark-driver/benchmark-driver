require 'benchmark_driver/struct'
require 'benchmark_driver/metric'
require 'benchmark_driver/default_job'
require 'benchmark_driver/default_job_parser'
require 'tempfile'
require 'shellwords'

# Run only once, for testing
class BenchmarkDriver::Runner::Once
  # JobParser returns this, `BenchmarkDriver::Runner.runner_for` searches "*::Job"
  Job = Class.new(BenchmarkDriver::DefaultJob)
  # Dynamically fetched and used by `BenchmarkDriver::JobParser.parse`
  JobParser = BenchmarkDriver::DefaultJobParser.for(Job)

  METRICS_TYPE = BenchmarkDriver::Metrics::Type.new(unit: 'i/s')

  # @param [BenchmarkDriver::Config::RunnerConfig] config
  # @param [BenchmarkDriver::Output] output
  def initialize(config:, output:)
    @config = config
    @output = output
  end

  # This method is dynamically called by `BenchmarkDriver::JobRunner.run`
  # @param [Array<BenchmarkDriver::Default::Job>] jobs
  def run(jobs)
    @output.metrics_type = METRICS_TYPE

    jobs = jobs.map do |job|
      Job.new(job.to_h.merge(loop_count: 1)) # to show this on output
    end

    @output.with_benchmark do
      jobs.each do |job|
        @output.with_job(name: job.name) do
          job.runnable_execs(@config.executables).each do |exec|
            metrics = run_benchmark(job, exec: exec) # no repeat support
            @output.with_context(name: exec.name, executable: exec) do
              @output.report(metrics)
            end
          end
        end
      end
    end
  end

  private

  # @param [BenchmarkDriver::Runner::Ips::Job] job - loop_count is not nil
  # @param [BenchmarkDriver::Config::Executable] exec
  # @return [BenchmarkDriver::Metrics]
  def run_benchmark(job, exec:)
    benchmark = BenchmarkScript.new(
      prelude:    job.prelude,
      script:     job.script,
      teardown:   job.teardown,
      loop_count: job.loop_count,
    )

    duration = Tempfile.open(['benchmark_driver-', '.rb']) do |f|
      with_script(benchmark.render(result: f.path)) do |path|
        execute(*exec.command, path)
      end
      Float(f.read)
    end

    BenchmarkDriver::Metrics.new(
      value: 1.0 / duration,
      duration: duration,
      executable: exec,
    )
  end

  def with_script(script)
    if @config.verbose >= 2
      sep = '-' * 30
      $stdout.puts "\n\n#{sep}[Script begin]#{sep}\n#{script}#{sep}[Script end]#{sep}\n\n"
    end

    Tempfile.open(['benchmark_driver-', '.rb']) do |f|
      f.puts script
      f.close
      return yield(f.path)
    end
  end

  def execute(*args)
    output = IO.popen(args, err: [:child, :out], &:read) # handle stdout?
    unless $?.success?
      raise "Failed to execute: #{args.shelljoin} (status: #{$?.exitstatus})"
    end
    output
  end

  # @param [String] prelude
  # @param [String] script
  # @param [String] teardown
  # @param [Integer] loop_count
  BenchmarkScript = ::BenchmarkDriver::Struct.new(:prelude, :script, :teardown, :loop_count) do
    # @param [String] result - A file to write result
    def render(result:)
      <<-RUBY
#{prelude}
__bmdv_before = Time.now
#{script}
__bmdv_after = Time.now
File.write(#{result.dump}, (__bmdv_after - __bmdv_before).inspect)
#{teardown}
      RUBY
    end
  end
  private_constant :BenchmarkScript
end
