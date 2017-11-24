class Benchmark::Driver::DurationRunner
  # @param [Benchmark::Driver::Configuration::Job] job
  def initialize(job)
    @job = job
  end

  # @param [Integer,Float] seconds
  # @param [Integer] unit_iters
  # @param [Proc] runner - should take (job, unit_iters) and return duration.
  # @return [Benchmark::Driver::BenchmarkResult]
  def run(seconds:, unit_iters:, runner:)
    duration   = 0.0
    iterations = 0
    unit_iters = unit_iters.to_i

    benchmark_until = Benchmark::Driver::Time.now + seconds
    while Benchmark::Driver::Time.now < benchmark_until
      duration   += runner.call(@job, unit_iters)
      iterations += unit_iters
    end

    Benchmark::Driver::BenchmarkResult.new(@job, duration, iterations)
  end
end
