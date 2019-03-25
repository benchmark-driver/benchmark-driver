require 'benchmark_driver/struct'
require 'benchmark_driver/metric'
require 'tempfile'
require 'shellwords'
require 'open3'

# Use stdout of ruby command
class BenchmarkDriver::Runner::CommandStdout
  # JobParser returns this, `BenchmarkDriver::Runner.runner_for` searches "*::Job"
  Job = ::BenchmarkDriver::Struct.new(
    :name,              # @param [String] name - This is mandatory for all runner
    :metrics,           # @param [Array<BenchmarkDriver::Metric>]
    :command,           # @param [Array<String>]
    :working_directory, # @param [String,NilClass]
    :stdout_to_metrics, # @param [String]
  )
  # Dynamically fetched and used by `BenchmarkDriver::JobParser.parse`
  class << JobParser = Module.new
    # @param [String] name
    # @param [String] command
    # @param [String,NilClass] working_directory
    # @param [Hash] metrics_type
    # @param [String] stdout_to_metrics
    def parse(name:, command:, working_directory: nil, metrics_type:, stdout_to_metrics:)
      Job.new(
        name: name,
        command: command.shellsplit,
        working_directory: working_directory,
        metrics: parse_metrics(metrics_type),
        stdout_to_metrics: stdout_to_metrics,
      )
    end

    private

    def parse_metrics(unit:, name: nil, larger_better: nil, worse_word: nil)
      name ||= unit
      metric = BenchmarkDriver::Metric.new(
        name: name,
        unit: unit,
        larger_better: larger_better,
        worse_word: worse_word,
      )
      [metric]
    end
  end

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
    metric = jobs.first.metrics.first

    @output.with_benchmark do
      jobs.each do |job|
        @output.with_job(name: job.name) do
          @contexts.each do |context|
            exec = context.executable
            result = BenchmarkDriver::Repeater.with_repeat(config: @config, larger_better: metric.larger_better) do
              stdout = with_chdir(job.working_directory) do
                with_ruby_prefix(exec) { execute(*exec.command, *job.command) }
              end
              StdoutToMetrics.new(
                stdout: stdout,
                stdout_to_metrics: job.stdout_to_metrics,
              ).metrics_value
            end

            @output.with_context(name: exec.name, executable: exec) do
              @output.report(values: { metric => result.value })
            end
          end
        end
      end
    end
  end

  private

  def with_ruby_prefix(executable, &block)
    env = ENV.to_h.dup
    ENV['PATH'] = "#{File.dirname(executable.command.first)}:#{ENV['PATH']}"
    block.call
  ensure
    ENV.replace(env)
  end

  def with_chdir(working_directory, &block)
    if working_directory
      Dir.chdir(working_directory) { block.call }
    else
      block.call
    end
  end

  def execute(*args)
    stdout, stderr, status = Open3.capture3(*args)
    unless status.success?
      raise "Failed to execute: #{args.shelljoin} (status: #{$?.exitstatus}):\n[stdout]:\n#{stdout}\n[stderr]:\n#{stderr}"
    end
    stdout
  end

  StdoutToMetrics = ::BenchmarkDriver::Struct.new(:stdout, :stdout_to_metrics) do
    def metrics_value
      eval(stdout_to_metrics, binding)
    end
  end
  private_constant :StdoutToMetrics
end
