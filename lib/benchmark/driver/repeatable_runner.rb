class Benchmark::Driver::RepeatableRunner
  # @param [Benchmark::Driver::Configuration::Job] job
  def initialize(job)
    @job = job
  end

  # @param [Integer] repeat_count
  # @param [Proc] runner - should take (job, unit_iters) and return duration.
  # @return [Benchmark::Driver::BenchmarkResult]
  def run(repeat_count:, runner:)
    real_times = (repeat_count || 1).times.map do
      runner.call(@job, @job.loop_count)
    end
    Benchmark::Driver::BenchmarkResult.new(@job).tap do |result|
      result.real = real_times.select { |d| d > 0 }.min || real_times.max
    end
  end
end
