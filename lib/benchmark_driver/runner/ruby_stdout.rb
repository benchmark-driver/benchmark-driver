require 'benchmark_driver/struct'
require 'benchmark_driver/metric'
require 'tempfile'
require 'shellwords'
require 'open3'

# Use stdout of ruby command
class BenchmarkDriver::Runner::RubyStdout
  # JobParser returns this, `BenchmarkDriver::Runner.runner_for` searches "*::Job"
  Job = ::BenchmarkDriver::Struct.new(
    :name,                   # @param [String] name - This is mandatory for all runner
    :command,                # @param [Array<String>]
    :working_directory,      # @param [String,NilClass]
    :metrics,                # @param [Array<BenchmarkDriver::Metric>]
    :value_from_stdout,      # @param [String]
    :environment_from_stdout # @param [Hash{ String => String }]
  )
  # Dynamically fetched and used by `BenchmarkDriver::JobParser.parse`
  class << JobParser = Module.new
    # @param [String] name
    # @param [String] command
    # @param [String,NilClass] working_directory
    # @param [Hash] metrics_type
    # @param [String] stdout_to_metrics
    def parse(name:, command:, working_directory: nil, metrics:, environment: {})
      unless metrics.is_a?(Hash)
        raise ArgumentError.new("metrics must be Hash, but got #{metrics.class}")
      end
      if metrics.size == 0
        raise ArgumentError.new('At least one metric must be specified"')
      elsif metrics.size != 1
        raise NotImplementedError.new('Having multiple metrics is not supported yet')
      end

      metric, value_from_stdout = parse_metric(*metrics.first)
      environment_from_stdout = Hash[environment.map { |k, v| [k, parse_environment(v)] }]

      Job.new(
        name: name,
        command: command.shellsplit,
        working_directory: working_directory,
        metrics: [metric],
        value_from_stdout: value_from_stdout,
        environment_from_stdout: environment_from_stdout,
      )
    end

    private

    def parse_metric(name, unit:, from_stdout:, larger_better: true, worse_word: 'slower')
      metric = BenchmarkDriver::Metric.new(
        name: name,
        unit: unit,
        larger_better: larger_better,
        worse_word: worse_word,
      )
      [metric, from_stdout]
    end

    def parse_environment(from_stdout:)
      from_stdout
    end
  end

  # @param [BenchmarkDriver::Config::RunnerConfig] config
  # @param [BenchmarkDriver::Output] output
  def initialize(config:, output:)
    @config = config
    @output = output
  end

  # This method is dynamically called by `BenchmarkDriver::JobRunner.run`
  # @param [Array<BenchmarkDriver::Default::Job>] jobs
  def run(jobs)
    metric = jobs.first.metrics.first
    @output.metrics = [metric]

    @output.with_benchmark do
      jobs.each do |job|
        @output.with_job(name: job.name) do
          @config.executables.each do |exec|
            repeat_params = { config: @config, larger_better: metric.larger_better }
            value, environment = BenchmarkDriver::Repeater.with_repeat(repeat_params) do
              stdout = with_chdir(job.working_directory) do
                with_ruby_prefix(exec) { execute(*exec.command, *job.command) }
              end
              script = StdoutToMetrics.new(
                stdout: stdout,
                value_from_stdout: job.value_from_stdout,
                environment_from_stdout: job.environment_from_stdout,
              )
              [script.value, script.environment]
            end

            @output.with_context(name: exec.name, executable: exec, environment: environment) do
              @output.report(value: value, metric: metric)
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

  # Return multiple times and return the best metrics
  def with_repeat(metric, &block)
    value_environments = @config.repeat_count.times.map do
      block.call
    end
    value_environments.sort_by do |value, _|
      if metric.larger_better
        value
      else
        -value
      end
    end.last
  end

  StdoutToMetrics = ::BenchmarkDriver::Struct.new(:stdout, :value_from_stdout, :environment_from_stdout) do
    def value
      value = eval(value_from_stdout, binding)
    end

    def environment
      ret = {}
      environment_from_stdout.each do |name, from_stdout|
        ret[name] = eval(from_stdout, binding)
      end
      ret
    end
  end
  private_constant :StdoutToMetrics
end
