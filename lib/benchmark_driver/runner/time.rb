require 'benchmark_driver/runner/ips'

class BenchmarkDriver::Runner::Time < BenchmarkDriver::Runner::Ips
  # JobParser returns this, `BenchmarkDriver::Runner.runner_for` searches "*::Job"
  Job = Class.new(BenchmarkDriver::DefaultJob)
  # Dynamically fetched and used by `BenchmarkDriver::JobParser.parse`
  JobParser = BenchmarkDriver::DefaultJobParser.for(Job)

  METRICS_TYPE = BenchmarkDriver::Metrics::Type.new(unit: 's')

  # Overriding BenchmarkDriver::Runner::Ips#set_metrics_type
  def set_metrics_type
    @output.metrics_type = METRICS_TYPE
  end

  # Overriding BenchmarkDriver::Runner::Ips#build_metrics
  def build_metrics(duration:, executable:, loop_count:)
    BenchmarkDriver::Metrics.new(
      value: duration,
      executable: executable,
    )
  end
end
