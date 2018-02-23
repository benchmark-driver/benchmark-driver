module BenchmarkDriver
  module Runner
    require 'benchmark_driver/runner/ips'
    require 'benchmark_driver/runner/memory'
    require 'benchmark_driver/runner/time'
  end

  class << Runner
    # Main function which is used by both CLI and `Benchmark.driver`.
    # @param [Array<BenchmarkDriver::*::Job>] jobs
    # @param [BenchmarkDriver::Config] config
    def run(jobs, config:)
      output_class = Output.find(config.output_type)
      runner_config = Config::RunnerConfig.new(
        executables: config.executables,
        repeat_count: config.repeat_count,
        run_duration: config.run_duration,
      )

      jobs.group_by(&:class).each do |klass, jobs_group|
        runner = runner_for(klass)
        output = output_class.new(
          jobs: jobs,
          executables: config.executables,
          metrics_type: runner::MetricsType,
        )
        runner.new(config: runner_config, output: output).run(jobs)
      end
    end

    private

    # Dynamically find class (BenchmarkDriver::*::JobRunner) for plugin support
    # @param [Class] klass - BenchmarkDriver::*::Job
    # @return [Class]
    def runner_for(klass)
      unless match = klass.name.match(/\ABenchmarkDriver::Runner::(?<namespace>[^:]+)::Job\z/)
        raise "Unexpected job class: #{klass}"
      end
      BenchmarkDriver.const_get("Runner::#{match[:namespace]}", false)
    end
  end
end
