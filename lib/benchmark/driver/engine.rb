require 'benchmark/output'
require 'benchmark/profiler'
require 'benchmark/runner'

class Benchmark::Driver::Engine
  # @param [Benchmark::Driver::Configuration] config
  def run(config)
    output   = Benchmark::Output::Ips.new
    runner   = Benchmark::Runner::Eval.new(output)
    profiler = Benchmark::Profiler::RealTime.new

    runner.run(config, profiler: profiler)
  end
end
