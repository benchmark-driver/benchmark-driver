class Benchmark::Driver
  class BenchmarkResult < Struct.new(
    :name,            # @param [String]
    :metrics_by_exec, # @param [Hash{ Executable => BenchmarkMetrics }]
  )
    def iterations_of(exec)
      metrics_by_exec.fetch(exec).iterations
    end

    def elapsed_time_of(exec)
      metrics_by_exec.fetch(exec).elapsed_time
    end

    def ips_of(exec)
      iterations_of(exec) / elapsed_time_of(exec)
    end
  end
end
