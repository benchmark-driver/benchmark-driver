require 'benchmark_driver/version'

class BenchmarkDriver
  # @param [Integer] duration - Benchmark duration in seconds
  def initialize(duration: 5)
    @duration = 5
    @execs = [Executable.new('ruby1', 'ruby'), Executable.new('ruby2', 'ruby')]
  end

  # @param [Hash,Array<Hash>] hashes
  def run(hashes)
    hashes = [hashes] if hashes.is_a?(Hash)
    benchmarks = hashes.map do |hash|
      Benchmark.new(Hash[hash.map { |k, v| [k.to_sym, v] }])
    end
    if benchmarks.empty?
      abort 'No benchmark is specified in YAML'
    end

    results = benchmarks.map do |benchmark|
      iterations = calc_iterations(benchmark)
      time_by_exec = run_benchmark(benchmark, iterations)
      BenchmarkResult.new(benchmark.name, iterations, time_by_exec)
    end
    ExecutionTimeReporter.report(@execs, results)
  end

  private

  def calc_iterations(benchmark)
    9999
  end

  def run_benchmark(benchmark, iterations)
    {}.tap do |time_by_exec|
      time_by_exec['ruby1'] = 100
      time_by_exec['ruby2'] = 200
    end
  end

  class Benchmark
    # @param [String] name
    # @param [String] prelude
    # @param [String] script
    def initialize(name:, prelude: '', script:)
      @name = name
      @prelude = prelude
      @script = script
    end
    attr_reader :name, :prelude, :script
  end

  class BenchmarkResult < Struct.new(
    :name,         # @param [String]
    :iterations,   # @param [Integer]
    :time_by_exec, # @param [Hash{ String => Float }]
  )
  end

  class Executable < Struct.new(
    :name, # @param [String]
    :path, # @param [String]
  )
  end

  module ExecutionTimeReporter
    class << self
      # @param [Array<Executable>] execs
      # @param [Array<BenchmarkResult>] results
      def report(execs, results)
        puts "benchmark results:"
        puts "Execution time (sec)"
        puts "name       #{execs.map(&:name).join(' ')}"
        results.each do |result|
          print "#{result.name} "
          execs.each do |exec|
            print "#{result.time_by_exec.fetch(exec.name)}   "
          end
          puts
        end
        puts

        if execs.size > 1
          report_speedup(execs, results)
        end
      end

      private

      def report_speedup(execs, results)
        compared = execs.first
        rest = execs - [compared]
        puts "Speedup ratio: compare with the result of `#{compared.name}' (greater is better)"
        puts "name       #{rest.map(&:name).join(' ')}"
        results.each do |result|
          print "#{result.name} "
          rest.each do |exec|
            print "#{result.time_by_exec.fetch(exec.name)}   "
          end
          puts
        end
        puts
      end
    end
  end
end
