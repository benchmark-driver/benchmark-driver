require 'benchmark_driver/struct'

module BenchmarkDriver
  module Default
    BenchmarkScript = ::BenchmarkDriver::Struct.new(
      :before, # @param [String]
      :script, # @param [String]
      :after,  # @param [String]
    )
    private_constant :BenchmarkScript
  end
end
