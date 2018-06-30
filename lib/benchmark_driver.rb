require 'benchmark_driver/config'
require 'benchmark_driver/job_parser'
require 'benchmark_driver/output'
require 'benchmark_driver/rbenv'
require 'benchmark_driver/repeater'
require 'benchmark_driver/ruby_interface'
require 'benchmark_driver/runner'
require 'benchmark_driver/version'

require 'benchmark'
def Benchmark.driver(**args, &block)
  BenchmarkDriver::RubyInterface.run(**args, &block)
end
