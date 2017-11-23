# @param [Benchmark::Driver::Configuration::Job] job
# @param [Float] duration - Duration in seconds
# @param [Integer] iterations
class Benchmark::Driver::BenchmarkResult < Struct.new(:job, :duration, :iterations)
  def ips
    iterations / duration
  end

  def ip100ms
    ips / 10
  end
end
