require 'benchmark_driver/struct'
require 'benchmark_driver/metric'
require 'benchmark_driver/default_job'
require 'benchmark_driver/default_job_parser'
require 'tempfile'
require 'shellwords'

# Show iteration per second.
class BenchmarkDriver::Runner::Ips
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
    if jobs.any? { |job| job.loop_count.nil? }
      @output.with_warmup do
        jobs = jobs.map do |job|
          next job if job.loop_count # skip warmup if loop_count is set

          @output.with_job(name: job.name) do
            context = job.runnable_contexts(@contexts).first
            duration, loop_count = run_warmup(job, context: context)
            value, duration = value_duration(duration: duration, loop_count: loop_count)

            @output.with_context(name: context.name, executable: context.executable, gems: context.gems, prelude: context.prelude) do
              @output.report(values: { metric => value }, duration: duration, loop_count: loop_count)
            end

            loop_count = (loop_count.to_f * @config.run_duration / duration).floor
            Job.new(job.to_h.merge(loop_count: loop_count))
          end
        end
      end
    end

    @output.with_benchmark do
      jobs.each do |job|
        @output.with_job(name: job.name) do
          job.runnable_contexts(@contexts).each do |context|
            repeat_params = { config: @config, larger_better: true, rest_on_average: :average }
            result = BenchmarkDriver::Repeater.with_repeat(repeat_params) do
              run_benchmark(job, context: context)
            end
            value, duration = result.value
            @output.with_context(name: context.name, executable: context.executable, gems: context.gems, prelude: context.prelude) do
              @output.report(
                values: { metric => value },
                all_values: { metric => result.all_values },
                duration: duration,
                loop_count: job.loop_count,
              )
            end
          end
        end
      end
    end
  end

  private

  # @param [BenchmarkDriver::Runner::Ips::Job] job - loop_count is nil
  # @param [BenchmarkDriver::Context] context
  def run_warmup(job, context:)
    warmup = WarmupScript.new(
      preludes:   [context.prelude, job.prelude],
      script:     job.script,
      teardown:   job.teardown,
      loop_count: job.loop_count,
      first_warmup_duration: @config.run_duration / 6.0,  # default: 0.5
      second_warmup_duration: @config.run_duration / 3.0, # default: 1.0
    )

    duration, loop_count = Tempfile.open(['benchmark_driver-', '.rb']) do |f|
      with_script(warmup.render(result: f.path)) do |path|
        execute(*context.executable.command, path)
      end
      eval(f.read)
    end

    [duration, loop_count]
  end

  # @param [BenchmarkDriver::Runner::Ips::Job] job - loop_count is not nil
  # @param [BenchmarkDriver::Context] context
  # @return [BenchmarkDriver::Metrics]
  def run_benchmark(job, context:)
    benchmark = BenchmarkScript.new(
      preludes:   [context.prelude, job.prelude],
      script:     job.script,
      teardown:   job.teardown,
      loop_count: job.loop_count,
    )

    duration = Tempfile.open(['benchmark_driver-', '.rb']) do |f|
      with_script(benchmark.render(result: f.path)) do |path|
        IO.popen([*context.executable.command, path], &:read) # TODO: print stdout if verbose=2
        if $?.success?
          Float(f.read)
        else
          BenchmarkDriver::Result::ERROR
        end
      end
    end

    value_duration(
      loop_count: job.loop_count,
      duration: duration,
    )
  end

  # This method is overridden by BenchmarkDriver::Runner::Time
  def metric
    METRIC
  end

  # Overridden by BenchmarkDriver::Runner::Time
  def value_duration(duration:, loop_count:)
    if BenchmarkDriver::Result::ERROR.equal?(duration)
      [BenchmarkDriver::Result::ERROR, BenchmarkDriver::Result::ERROR]
    else
      [loop_count.to_f / duration, duration]
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
    IO.popen(args, &:read) # TODO: print stdout if verbose=2
    unless $?.success?
      raise "Failed to execute: #{args.shelljoin} (status: #{$?.exitstatus})"
    end
  end

  WarmupScript = ::BenchmarkDriver::Struct.new(:preludes, :script, :teardown, :loop_count, :first_warmup_duration, :second_warmup_duration) do
    # @param [String] result - A file to write result
    def render(result:)
      prelude = preludes.reject(&:nil?).reject(&:empty?).join("\n")
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
__bmdv_ip100ms = (__bmdv_i.to_f / (__bmdv_after - __bmdv_before) / 10.0).ceil
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

File.write(#{result.dump}, [__bmdv_duration, __bmdv_loops].inspect)
      RUBY
    end
  end
  private_constant :WarmupScript

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

if #{loop_count} == 1
  __bmdv_empty_before = 0
  __bmdv_empty_after = 0
elsif Process.respond_to?(:clock_gettime) # Ruby 2.1+
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
      elsif times == 1
        return content
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
