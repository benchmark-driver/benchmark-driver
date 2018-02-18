require 'benchmark_driver/struct'
require 'benchmark_driver/metrics'
require 'benchmark_driver/default_job'
require 'benchmark_driver/default_job_parser'

class BenchmarkDriver::Runner::Ips
  Job = Class.new(BenchmarkDriver::DefaultJob)
  JobParser = BenchmarkDriver::DefaultJobParser.for(Job)

  METRICS_TYPE = BenchmarkDriver::Metrics::Type.new(unit: 'i/s')

  # @param [BenchmarkDriver::Config::RunnerConfig] config
  # @param [BenchmarkDriver::Output::*] output
  def initialize(config:, output:)
    @config = config
    @output = output
  end

  # This method is dynamically called by `BenchmarkDriver::JobRunner.run`
  # @param [Array<BenchmarkDriver::Default::Job>] jobs
  def run(jobs)
    @output.with_benchmark(METRICS_TYPE) do
      jobs.each do |job|
        @output.with_job(job) do
          @config.executables.each do |exec|
            @output.report(run_benchmark(exec, job))
          end
        end
      end
    end
  end

  private

  # @param [Array<BenchmarkDriver::Config::Executable>] executable
  # @param [Array<BenchmarkDriver::Default::Job>] jobs
  # @return [BenchmarkDriver::Metrics]
  def run_benchmark(executable, job)
    BenchmarkDriver::Metrics.new(
      value: 1.0,
      executable: executable,
    )
  end

  BenchmarkScript = ::BenchmarkDriver::Struct.new(
    :before, # @param [String]
    :script, # @param [String]
    :after,  # @param [String]
  )
  private_constant :BenchmarkScript
end
