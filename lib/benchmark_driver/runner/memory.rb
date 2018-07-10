require 'benchmark_driver/struct'
require 'benchmark_driver/metric'
require 'benchmark_driver/default_job'
require 'benchmark_driver/default_job_parser'
require 'tempfile'
require 'shellwords'

# Max resident set size
class BenchmarkDriver::Runner::Memory
  METRIC = BenchmarkDriver::Metric.new(
    name: 'Max resident set size', unit: 'bytes', larger_better: false, worse_word: 'larger',
  )

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
    # Currently Linux's time(1) support only...
    if Etc.uname.fetch(:sysname) != 'Linux'
      raise "memory output is not supported for '#{Etc.uname[:sysname]}' for now"
    end

    if jobs.any? { |job| job.loop_count.nil? }
      jobs = jobs.map do |job|
        job.loop_count ? job : Job.new(job.to_h.merge(loop_count: 1))
      end
    end

    @output.with_benchmark do
      jobs.each do |job|
        @output.with_job(name: job.name) do
          job.runnable_contexts(@contexts).each do |context|
            value = BenchmarkDriver::Repeater.with_repeat(config: @config, larger_better: false) do
              run_benchmark(job, context: context)
            end
            @output.with_context(name: context.name, executable: context.executable, gems: context.gems, prelude: context.prelude) do
              @output.report(values: { METRIC => value }, loop_count: job.loop_count)
            end
          end
        end
      end
    end
  end

  private

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

    with_script(benchmark.render) do |path|
      output = IO.popen(['/usr/bin/time', *context.executable.command, path], err: [:child, :out], &:read)
      if $?.success?
        match_data = /^(?<user>\d+.\d+)user\s+(?<system>\d+.\d+)system\s+(?<elapsed1>\d+):(?<elapsed2>\d+.\d+)elapsed.+\([^\s]+\s+(?<maxresident>\d+)maxresident\)k$/.match(output)
        raise "Unexpected format given from /usr/bin/time:\n#{out}" unless match_data[:maxresident]

        Integer(match_data[:maxresident]) * 1000.0 # kilobytes -> bytes
      else
        $stdout.print(output)
        BenchmarkDriver::Result::ERROR
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

  # @param [String] prelude
  # @param [String] script
  # @param [String] teardown
  # @param [Integer] loop_count
  BenchmarkScript = ::BenchmarkDriver::Struct.new(:preludes, :script, :teardown, :loop_count) do
    def render
      prelude = preludes.reject(&:nil?).reject(&:empty?).join("\n")
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
