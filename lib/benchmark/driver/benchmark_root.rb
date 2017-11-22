class Benchmark::Driver
  class BenchmarkRoot
    # @param [String] name
    # @param [String] prelude
    # @param [Integer,nil] loop_count
    # @param [String,nil]  benchmark  - For running single instant benchmark
    # @param [Array<Hash>] benchmarks - For running multiple benchmarks
    def initialize(name:, prelude: '', loop_count: nil, benchmark: nil, benchmarks: [])
      if benchmark
        unless benchmarks.empty?
          raise ArgumentError.new("Only either :benchmark or :benchmarks can be specified")
        end
        @benchmarks = [BenchmarkScript.new(name: name, prelude: prelude, benchmark: benchmark)]
      else
        @benchmarks = benchmarks.map do |hash|
          BenchmarkScript.new(Hash[hash.map { |k, v| [k.to_sym, v] }]).tap do |b|
            b.inherit_root(prelude: prelude, loop_count: loop_count)
          end
        end
      end
    end

    # @return [Array<BenchmarkScript>]
    attr_reader :benchmarks
  end
end
