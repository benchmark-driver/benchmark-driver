require 'benchmark_driver/struct'

class BenchmarkDriver::Runner::Default
  BenchmarkScript = ::BenchmarkDriver::Struct.new(
    :before, # @param [String]
    :script, # @param [String]
    :after,  # @param [String]
  )
  private_constant :BenchmarkScript
end
