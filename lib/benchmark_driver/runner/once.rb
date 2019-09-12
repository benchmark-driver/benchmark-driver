require 'benchmark_driver/struct'
require 'benchmark_driver/metric'
require 'benchmark_driver/default_job'
require 'benchmark_driver/default_job_parser'
require 'tempfile'
require 'shellwords'

# Run only once, for testing
class BenchmarkDriver::Runner::Once
  METRIC = BenchmarkDriver::Metric.new(name: 'Iteration per second', unit: 'i/s')

  # JobParser returns this, `BenchmarkDriver::Runner.runner_for` searches "*::Job"
  Job = Class.new(BenchmarkDriver::DefaultJob)
  # Dynamically fetched and used by `BenchmarkDriver::JobParser.parse`
  JobParser = BenchmarkDriver::DefaultJobParser.for(klass: Job, metrics: [METRIC])

  # @param [BenchmarkDriver::Config::RunnerConfig] config
  # @param [BenchmarkDriver::Output] output
  # @param [BenchmarkDriver::Context] contexts
  def initialize(config:, output:, contexts:)
    @config = config
    @output = output
    @contexts = contexts
  end

  # This method is dynamically called by `BenchmarkDriver::JobRunner.run`
  # @param [Array<BenchmarkDriver::Default::Job>] jobs
  def run(jobs)
    jobs = jobs.map do |job|
      Job.new(**job.to_h.merge(loop_count: 1)) # to show this on output
    end

    @output.with_benchmark do
      jobs.each do |job|
        @output.with_job(name: job.name) do
          job.runnable_contexts(@contexts).each do |context|
            duration = run_benchmark(job, context: context) # no repeat support
            if BenchmarkDriver::Result::ERROR.equal?(duration)
              value = BenchmarkDriver::Result::ERROR
            else
              value = 1.0 / duration
            end

            @output.with_context(name: context.name, executable: context.executable, gems: context.gems, prelude: context.prelude) do
              @output.report(values: { METRIC => value }, duration: duration, loop_count: 1)
            end
          end
        end
      end
    end
  end

  private

  # @param [BenchmarkDriver::Runner::Ips::Job] job - loop_count is not nil
  # @param [BenchmarkDriver::Context] context
  # @return [Float] duration
  def run_benchmark(job, context:)
    benchmark = BenchmarkScript.new(
      preludes:   [context.prelude, job.prelude],
      script:     job.script,
      teardown:   job.teardown,
      loop_count: job.loop_count,
    )

    Tempfile.open(['benchmark_driver-', '.rb']) do |f|
      with_script(benchmark.render(result: f.path)) do |path|
        IO.popen([*context.executable.command, path], &:read) # TODO: print stdout if verbose=2
        if $?.success?
          Float(f.read)
        else
          BenchmarkDriver::Result::ERROR
        end
      end
    end
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
  BenchmarkScript = ::BenchmarkDriver::Struct.new(:preludes, :script, :teardown, :loop_count) do
    # @param [String] result - A file to write result
    def render(result:)
      prelude = preludes.reject(&:nil?).reject(&:empty?).join("\n")
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
