require 'benchmark_driver/runner/ips'

class BenchmarkDriver::Runner::Time < BenchmarkDriver::Runner::Ips
  # JobParser returns this, `BenchmarkDriver::Runner.runner_for` searches "*::Job"
  Job = Class.new(BenchmarkDriver::DefaultJob)
  # Dynamically fetched and used by `BenchmarkDriver::JobParser.parse`
  JobParser = BenchmarkDriver::DefaultJobParser.for(Job)

  METRICS_TYPE = BenchmarkDriver::Metrics::Type.new(unit: 's', larger_better: false)

  # Overriding BenchmarkDriver::Runner::Ips#set_metrics_type
  def set_metrics_type
    @output.metrics_type = METRICS_TYPE
  end

  # Overriding BenchmarkDriver::Runner::Ips#value_duration
  def value_duration(duration:, loop_count:)
    [duration, duration]
  end

  # Overriding BenchmarkDriver::Runner::Ips#larger_better?
  def larger_better?
    false
  end
end
