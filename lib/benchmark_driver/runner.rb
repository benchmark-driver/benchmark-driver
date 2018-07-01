module BenchmarkDriver
  module Runner
    require 'benchmark_driver/runner/command_stdout'
    require 'benchmark_driver/runner/ips'
    require 'benchmark_driver/runner/memory'
    require 'benchmark_driver/runner/once'
    require 'benchmark_driver/runner/recorded'
    require 'benchmark_driver/runner/ruby_stdout'
    require 'benchmark_driver/runner/time'
  end

  class << Runner
    # Main function which is used by both CLI and `Benchmark.driver`.
    # @param [Array<BenchmarkDriver::*::Job>] jobs
    # @param [BenchmarkDriver::Config] config
    def run(jobs, config:)
      if config.verbose >= 1
        config.executables.each do |exec|
          $stdout.puts "#{exec.name}: #{IO.popen([*exec.command, '-v'], &:read)}"
        end
      end

      runner_config = Config::RunnerConfig.new(
        executables: config.executables,
        repeat_count: config.repeat_count,
        repeat_result: config.repeat_result,
        run_duration: config.run_duration,
        verbose: config.verbose,
      )

      jobs.group_by(&:class).each do |klass, klass_jobs|
        klass_jobs.group_by(&:metrics).each do |metrics, metrics_jobs|
          runner = runner_for(klass)
          output = Output.new(
            type: config.output_type,
            metrics: metrics,
            jobs: jobs.map { |job| BenchmarkDriver::Job.new(name: job.name) },
            contexts: config.executables.map { |exec|
              BenchmarkDriver::Context.new(name: exec.name, executable: exec)
            },
          )
          with_clean_env do
            runner.new(config: runner_config, output: output).run(metrics_jobs)
          end
        end
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

    def with_clean_env(&block)
      require 'bundler'
      Bundler.with_clean_env do
        block.call
      end
    rescue LoadError
      block.call
    end
  end
end
