require 'benchmark_driver/version'
require 'benchmark_driver/job_parser'

module BenchmarkDriver
  # Main function which is used by both CLI and `Benchmark.driver`.
  # @param [Array<BenchmarkDriver::Job>] jobs
  # @param [BenchmarkDriver::Config] config
  def self.run(jobs, config:)
  end
end
