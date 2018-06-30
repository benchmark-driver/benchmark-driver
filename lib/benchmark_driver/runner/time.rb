require 'benchmark_driver/runner/ips'

class BenchmarkDriver::Runner::Time < BenchmarkDriver::Runner::Ips
  # JobParser returns this, `BenchmarkDriver::Runner.runner_for` searches "*::Job"
  Job = Class.new(BenchmarkDriver::DefaultJob)
  # Dynamically fetched and used by `BenchmarkDriver::JobParser.parse`
  JobParser = BenchmarkDriver::DefaultJobParser.for(Job)

  METRIC = BenchmarkDriver::Metric.new(name: 'Execution time', unit: 's', larger_better: false)

  # Overriding BenchmarkDriver::Runner::Ips#metric
  def metric
    METRIC
  end

  # Overriding BenchmarkDriver::Runner::Ips#value_duration
  def value_duration(duration:, loop_count:)
    [duration, duration]
  end
end
