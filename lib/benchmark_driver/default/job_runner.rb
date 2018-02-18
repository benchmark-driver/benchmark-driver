require 'benchmark_driver/default/benchmark_script'

module BenchmarkDriver
  module Default
    class JobRunner
      # @param [BenchmarkDriver::Config::RunnerConfig] config
      # @param [BenchmarkDriver::Output::*] output
      def initialize(config:, output:)
        @config = config
        @output = output
      end

      # This method is dynamically called by `BenchmarkDriver::JobRunner.run`
      # @param [Array<BenchmarkDriver::Default::Job>] jobs
      def run(jobs)
        @output.with_benchmark do
          jobs.each do |job|
            @output.with_job(job) do
              @output.report(nil)
            end
          end
        end
      end
    end
  end
end
