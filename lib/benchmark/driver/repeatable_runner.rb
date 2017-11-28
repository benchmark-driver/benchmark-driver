class Benchmark::Driver::RepeatableRunner
  # @param [Benchmark::Driver::Configuration::Job] job
  def initialize(job)
    @job = job
  end

  # @param [Integer] repeat_count
  # @param [Proc] runner - should take (job, unit_iters) and return duration.
  # @return [Benchmark::Driver::BenchmarkResult]
  def run(repeat_count:, runner:)
    durations = (repeat_count || 1).times.map do
      runner.call(@job, @job.loop_count)
    end
    duration = durations.select { |d| d > 0 }.min || durations.max
    result = Benchmark::Driver::BenchmarkResult.new(@job, duration, @job.loop_count)
  end
end
