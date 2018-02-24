require 'benchmark_driver/struct'
require 'benchmark_driver/metrics'
require 'benchmark_driver/default_job'
require 'benchmark_driver/default_job_parser'
require 'tempfile'
require 'shellwords'

# Show iteration per second.
class BenchmarkDriver::Runner::Ips
  # JobParser returns this, `BenchmarkDriver::Runner.runner_for` searches "*::Job"
  Job = Class.new(BenchmarkDriver::DefaultJob)
  # Dynamically fetched and used by `BenchmarkDriver::JobParser.parse`
  JobParser = BenchmarkDriver::DefaultJobParser.for(Job)
  # Passed to `output` by `BenchmarkDriver::Runner.run`
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
            result = run_warmup(job, exec: @config.executables.first)
            metrics = build_metrics(result)
            @output.report(metrics)

            loop_count = (result.fetch(:loop_count).to_f * @config.run_duration / result.fetch(:duration)).floor
            Job.new(job.to_h.merge(loop_count: loop_count))
          end
        end
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

  # @param [BenchmarkDriver::Runner::Ips::Job] job - loop_count is nil
  # @param [BenchmarkDriver::Config::Executable] exec
  def run_warmup(job, exec:)
    warmup = WarmupScript.new(
      prelude:    job.prelude,
      script:     job.script,
      teardown:   job.teardown,
      loop_count: job.loop_count,
      first_warmup_duration: @config.run_duration / 6.0,  # default: 0.5
      second_warmup_duration: @config.run_duration / 3.0, # default: 1.0
    )

    hash = Tempfile.open(['benchmark_driver-', '.rb']) do |f|
      with_script(warmup.render(result: f.path)) do |path|
        execute(*exec.command, path)
      end
      eval(f.read)
    end

    hash.merge(executable: exec)
  end

  # Return multiple times and return the best metrics
  def with_repeat(repeat_times, &block)
    all_metrics = repeat_times.times.map do
      block.call
    end
    all_metrics.sort_by do |metrics|
      metrics.value
    end.last
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

    duration = Tempfile.open(['benchmark_driver-', '.rb']) do |f|
      with_script(benchmark.render(result: f.path)) do |path|
        execute(*exec.command, path)
      end
      Float(f.read)
    end

    build_metrics(
      loop_count: job.loop_count,
      duration: duration,
      executable: exec,
    )
  end

  # This method is overridden by BenchmarkDriver::Runner::Time
  def build_metrics(duration:, executable:, loop_count:)
    BenchmarkDriver::Metrics.new(
      value: loop_count.to_f / duration,
      duration: duration,
      executable: executable,
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
    IO.popen(args, &:read) # handle stdout?
    unless $?.success?
      raise "Failed to execute: #{args.shelljoin} (status: #{$?.exitstatus})"
    end
  end

  WarmupScript = ::BenchmarkDriver::Struct.new(:prelude, :script, :teardown, :loop_count, :first_warmup_duration, :second_warmup_duration) do
    # @param [String] result - A file to write result
    def render(result:)
      <<-RUBY
#{prelude}

# first warmup
__bmdv_i = 0
__bmdv_before = Time.now
__bmdv_target = __bmdv_before + #{first_warmup_duration}
while Time.now < __bmdv_target
  #{script}
  __bmdv_i += 1
end
__bmdv_after = Time.now

# second warmup
__bmdv_ip100ms = (__bmdv_i.to_f / (__bmdv_after - __bmdv_before) / 10.0).floor
__bmdv_loops = 0
__bmdv_duration = 0.0
__bmdv_target = Time.now + #{second_warmup_duration}
while Time.now < __bmdv_target
  __bmdv_i = 0
  __bmdv_before = Time.now
  while __bmdv_i < __bmdv_ip100ms
    #{script}
    __bmdv_i += 1
  end
  __bmdv_after = Time.now

  __bmdv_loops += __bmdv_i
  __bmdv_duration += (__bmdv_after - __bmdv_before)
end

#{teardown}

File.write(#{result.dump}, { duration: __bmdv_duration, loop_count: __bmdv_loops }.inspect)
      RUBY
    end
  end
  private_constant :WarmupScript

  # @param [String] prelude
  # @param [String] script
  # @param [String] teardown
  # @param [Integer] loop_count
  BenchmarkScript = ::BenchmarkDriver::Struct.new(:prelude, :script, :teardown, :loop_count) do
    # @param [String] result - A file to write result
    def render(result:)
      <<-RUBY
#{prelude}

if Process.respond_to?(:clock_gettime) # Ruby 2.1+
  __bmdv_empty_before = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  #{while_loop('', loop_count)}
  __bmdv_empty_after = Process.clock_gettime(Process::CLOCK_MONOTONIC)
else
  __bmdv_empty_before = Time.now
  #{while_loop('', loop_count)}
  __bmdv_empty_after = Time.now
end

if Process.respond_to?(:clock_gettime) # Ruby 2.1+
  __bmdv_script_before = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  #{while_loop(script, loop_count)}
  __bmdv_script_after = Process.clock_gettime(Process::CLOCK_MONOTONIC)
else
  __bmdv_script_before = Time.now
  #{while_loop(script, loop_count)}
  __bmdv_script_after = Time.now
end

#{teardown}

File.write(
  #{result.dump},
  ((__bmdv_script_after - __bmdv_script_before) - (__bmdv_empty_after - __bmdv_empty_before)).inspect,
)
      RUBY
    end

    private

    def while_loop(content, times)
      if !times.is_a?(Integer) || times <= 0
        raise ArgumentError.new("Unexpected times: #{times.inspect}")
      end

      # TODO: execute in batch
      <<-RUBY
__bmdv_i = 0
while __bmdv_i < #{times}
  #{content}
  __bmdv_i += 1
end
      RUBY
    end
  end
  private_constant :BenchmarkScript
end
