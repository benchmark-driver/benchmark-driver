require 'benchmark_driver/struct'

module BenchmarkDriver
  DefaultJob = ::BenchmarkDriver::Struct.new(
    :name,       # @param [String] name
    :script,     # @param [String] benchmark
    :before,     # @param [String,nil] before (optional)
    :after,      # @param [String,nil] after (optional)
    :loop_count, # @param [Integer,nil] loop_count (optional)
    defaults: { before: '', after: '' },
  )
end
