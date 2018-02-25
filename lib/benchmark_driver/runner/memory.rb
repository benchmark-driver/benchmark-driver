require 'benchmark_driver/struct'
require 'benchmark_driver/metrics'
require 'benchmark_driver/default_job'
require 'benchmark_driver/default_job_parser'
require 'tempfile'
require 'shellwords'

# Max resident set size
class BenchmarkDriver::Runner::Memory
  # JobParser returns this, `BenchmarkDriver::Runner.runner_for` searches "*::Job"
  Job = Class.new(BenchmarkDriver::DefaultJob)
  # Dynamically fetched and used by `BenchmarkDriver::JobParser.parse`
  JobParser = BenchmarkDriver::DefaultJobParser.for(Job)

  METRICS_TYPE = BenchmarkDriver::Metrics::Type.new(unit: 'bytes', larger_better: false, worse_word: 'larger')

  # @param [BenchmarkDriver::Config::RunnerConfig] config
  # @param [BenchmarkDriver::Output::*] output
  def initialize(config:, output:)
    @config = config
    @output = output
  end

  # This method is dynamically called by `BenchmarkDriver::JobRunner.run`
  # @param [Array<BenchmarkDriver::Default::Job>] jobs
  def run(jobs)
    # Currently Linux's time(1) support only...
    if Etc.uname.fetch(:sysname) != 'Linux'
      raise "memory output is not supported for '#{Etc.uname[:sysname]}' for now"
    end

    @output.metrics_type = METRICS_TYPE

    if jobs.any? { |job| job.loop_count.nil? }
      jobs = jobs.map do |job|
        job.loop_count ? job : Job.new(job.to_h.merge(loop_count: 1))
      end
    end

    @output.with_benchmark do
      jobs.each do |job|
        @output.with_job(job) do
          @config.executables.each do |exec|
            best_metrics = with_repeat(@config.repeat_count) do
              run_benchmark(job, exec: exec)
            end
            @output.report(best_metrics)
          end
        end
      end
    end
  end

  private

  # Return multiple times and return the best metrics
  def with_repeat(repeat_times, &block)
    all_metrics = repeat_times.times.map do
      block.call
    end
    all_metrics.sort_by do |metrics|
      metrics.value
    end.first
  end

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

    output = with_script(benchmark.render) do |path|
      execute('/usr/bin/time', *exec.command, path)
    end

    match_data = /^(?<user>\d+.\d+)user\s+(?<system>\d+.\d+)system\s+(?<elapsed1>\d+):(?<elapsed2>\d+.\d+)elapsed.+\([^\s]+\s+(?<maxresident>\d+)maxresident\)k$/.match(output)
    raise "Unexpected format given from /usr/bin/time:\n#{out}" unless match_data[:maxresident]

    BenchmarkDriver::Metrics.new(
      value: Integer(match_data[:maxresident]) * 1000.0, # kilobytes -> bytes
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
    def render
      <<-RUBY
#{prelude}
#{while_loop(script, loop_count)}
#{teardown}
      RUBY
    end

    private

    def while_loop(content, times)
      if !times.is_a?(Integer) || times <= 0
        raise ArgumentError.new("Unexpected times: #{times.inspect}")
      end

      # TODO: execute in batch
      if times > 1
        <<-RUBY
__bmdv_i = 0
while __bmdv_i < #{times}
  #{content}
  __bmdv_i += 1
end
        RUBY
      else
        content
      end
    end
  end
  private_constant :BenchmarkScript
end
