require 'benchmark_driver/struct'

# All benchmark results should be expressed by this model.
module BenchmarkDriver
  Metrics = ::BenchmarkDriver::Struct.new(
    :value,      # @param [Float] - The main field of benchmark result
    :executable, # @param [BenchmarkDriver::Config::Executable] - Measured Ruby executable
    :loop_count, # @param [Integer,nil] - Times to run the script (optional)
  )

  Metrics::Type = ::BenchmarkDriver::Struct.new(
    :unit,          # @param [String] - A label of unit for the value.
    :larger_better, # @param [TrueClass,FalseClass] - If true, larger value is preferred when measured multiple times.
    defaults: { larger_better: true },
  )
end
