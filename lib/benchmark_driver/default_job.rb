require 'benchmark_driver/struct'

module BenchmarkDriver
  DefaultJob = ::BenchmarkDriver::Struct.new(
    :name,       # @param [String] name - This is mandatory for all runner
    :script,     # @param [String] benchmark
    :prelude,    # @param [String,nil] prelude (optional)
    :teardown,   # @param [String,nil] after (optional)
    :loop_count, # @param [Integer,nil] loop_count (optional)
    defaults: { prelude: '', teardown: '' },
  )
end
