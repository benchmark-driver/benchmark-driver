# @param [Benchmark::Driver::Configuration::Job] job
# @param [Integer] iterations - Executed iterations of benchmark script in the job
# @param [Float] real - Real time taken by the job
# @param [Integer] max_rss - Maximum resident set size of the process during its lifetime, in Kilobytes.
class Benchmark::Driver::BenchmarkResult < Struct.new(:job, :iterations, :real, :max_rss)
  alias :duration :real

  def ips
    iterations / real
  end

  def ip100ms
    ips / 10
  end

  def iterations
    # runner's warmup uses `result.ips` to calculate `job.loop_count`, and thus
    # at that moment `job.loop_count` isn't available and we need to use `super`.
    super || job.loop_count
  end
end
