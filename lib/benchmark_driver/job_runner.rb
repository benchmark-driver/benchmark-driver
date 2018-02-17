require 'benchmark_driver/default/job_runner'

module BenchmarkDriver
  class << JobRunner = Module.new
    # Main function which is used by both CLI and `Benchmark.driver`.
    # @param [Array<BenchmarkDriver::*::Job>] jobs
    # @param [BenchmarkDriver::Config] config
    def run(jobs, config:)
      jobs.group_by(&:class).each do |klass, jobs_group|
        runner = runner_for(klass)
        runner.run(jobs, config: config)
      end
    end

    private

    # Dynamically find class (BenchmarkDriver::*::JobRunner) for plugin support
    # @param [Class] klass - BenchmarkDriver::*::Job
    # @return [Class]
    def runner_for(klass)
      unless match = klass.name.match(/\ABenchmarkDriver::(?<namespace>[^:]+)::Job\z/)
        raise "Unexpected job class: #{klass}"
      end
      BenchmarkDriver.const_get("#{match[:namespace]}::JobRunner", false)
    end
  end
end
