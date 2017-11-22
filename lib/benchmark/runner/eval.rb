class Benchmark::Runner::Eval
  # @param [Benchmark::Output::*] output - Object that responds to #xxx and/or #yyy
  def initialize(output)
    @output = output
  end

  # @param [Benchmark::Driver::Configuration] config
  # @param [Benchmark::Profiler::*] profiler - Object that responds to #xxx and/or #yyy
  def run(config, profiler:)
  end
end
