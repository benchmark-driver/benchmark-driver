require 'benchmark_driver/ruby/job_runner'

module BenchmarkDriver
  class << JobRunner = Module.new
    # Main function which is used by both CLI and `Benchmark.driver`.
    # @param [Array<BenchmarkDriver::*::Job>] jobs
    # @param [BenchmarkDriver::Config] config
    def run(jobs, config:)
      jobs = filter_jobs(jobs, filters: config.filters)
      jobs.group_by(&:class).each do |klass, jobs_group|
        runner = runner_for(klass)
        runner.run(jobs, config: config)
      end
    end

    private

    # @param [Array<BenchmarkDriver::*::Job>] jobs
    # @param [Array<Regexp>] filters
    def filter_jobs(jobs, filters:)
      jobs.select do |job|
        filters.all? do |filter|
          job.name.match(filter)
        end
      end
    end

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
