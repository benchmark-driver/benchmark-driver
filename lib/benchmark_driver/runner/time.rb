require 'benchmark_driver/runner/ips'

class BenchmarkDriver::Runner::Time < BenchmarkDriver::Runner::Ips
  # JobParser returns this, `BenchmarkDriver::Runner.runner_for` searches "*::Job"
  Job = Class.new(BenchmarkDriver::DefaultJob)
  # Dynamically fetched and used by `BenchmarkDriver::JobParser.parse`
  JobParser = BenchmarkDriver::DefaultJobParser.for(Job)
  # Passed to `output` by `BenchmarkDriver::Runner.run`
  MetricsType = BenchmarkDriver::Metrics::Type.new(unit: 's')

  # Overriding BenchmarkDriver::Runner::Ips#build_metrics
  def build_metrics(duration:, executable:, loop_count:)
    BenchmarkDriver::Metrics.new(
      value: duration,
      duration: duration,
      executable: executable,
    )
  end
end
