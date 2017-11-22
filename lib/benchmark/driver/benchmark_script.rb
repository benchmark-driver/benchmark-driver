class Benchmark::Driver
  class BenchmarkScript
    # @param [String] name
    # @param [String] prelude
    # @param [String] benchmark
    def initialize(name:, prelude: '', loop_count: nil, benchmark:)
      @name = name
      @prelude = prelude
      @loop_count = loop_count
      @benchmark = benchmark
    end

    # @return [String]
    attr_reader :name

    # @return [Integer]
    attr_reader :loop_count

    def inherit_root(prelude:, loop_count:)
      @prelude = "#{prelude}\n#{@prelude}"
      if @loop_count.nil? && loop_count
        @loop_count = loop_count
      end
    end

    def overhead_script(iterations)
      <<-RUBY
#{@prelude}
__benchmark_driver_i = 0
while __benchmark_driver_i < #{iterations}
  __benchmark_driver_i += 1
end
      RUBY
    end

    def benchmark_script(iterations)
      <<-RUBY
#{@prelude}
__benchmark_driver_i = 0
while __benchmark_driver_i < #{iterations}
  __benchmark_driver_i += 1
#{@benchmark}
end
      RUBY
    end
  end
end
