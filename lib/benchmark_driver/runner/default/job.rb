require 'benchmark_driver/struct'

class BenchmarkDriver::Runner::Default
  Job = ::BenchmarkDriver::Struct.new(
    :name,       # @param [String] name
    :before,     # @param [String] before
    :script,     # @param [String] benchmark
    :after,      # @param [String] after
    :loop_count, # @param [Integer] loop_count
    defaults: { before: '', after: '' },
  )
end
