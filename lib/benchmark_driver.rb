require 'benchmark_driver/version'
require 'benchmark'
require 'tempfile'

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
      BenchmarkScript.new(Hash[hash.map { |k, v| [k.to_sym, v] }])
    end
    if benchmarks.empty?
      abort 'No benchmark is specified in YAML'
    end

    results = benchmarks.map do |benchmark|
      metrics_by_exec = {}
      @execs.each do |exec|
        iterations = calc_iterations(benchmark)
        elapsed_time = run_benchmark(exec, benchmark, iterations)
        metrics_by_exec[exec] = BenchmarkMetrics.new(iterations, elapsed_time)
      end
      BenchmarkResult.new(benchmark.name, metrics_by_exec)
    end
    ExecutionTimeReporter.report(@execs, results)
  end

  private

  def calc_iterations(benchmark)
    1000
  end

  def run_benchmark(exec, benchmark, iterations)
    measure_script(exec.path, benchmark.benchmark_script(iterations)) -
      measure_script(exec.path, benchmark.overhead_script(iterations))
  end

  def measure_script(ruby, script)
    Tempfile.create do |f|
      f.write(script)
      f.close

      cmd = "#{ruby} #{f.path}"
      Benchmark.measure { system(cmd, out: File::NULL) }.real
    end
  end

  class BenchmarkScript
    # @param [String] name
    # @param [String] prelude
    # @param [String] script
    def initialize(name:, prelude: '', script:)
      @name = name
      @prelude = prelude
      @script = script
    end
    attr_reader :name

    def overhead_script(iterations)
      <<-RUBY
#{@prelude}
i = 0
while i < #{iterations}
  i += 1
end
      RUBY
    end

    def benchmark_script(iterations)
      <<-RUBY
#{@prelude}
i = 0
while i < #{iterations}
  i += 1
#{@script}
end
      RUBY
    end
  end

  class BenchmarkResult < Struct.new(
    :name,            # @param [String]
    :metrics_by_exec, # @param [Hash{ Executable => BenchmarkMetrics }]
  )
    def iterations_of(exec)
      metrics_by_exec.fetch(exec).iterations
    end

    def elapsed_time_of(exec)
      metrics_by_exec.fetch(exec).elapsed_time
    end
  end

  class BenchmarkMetrics < Struct.new(
    :iterations,   # @param [Integer]
    :elapsed_time, # @param [Float] - Elapsed time in seconds
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
        puts "#{'%-16s' % 'name'} #{execs.map { |e| "%-8s" % e.name }.join(' ')}"

        results.each do |result|
          print '%-16s ' % result.name
          puts execs.map { |exec|
            "%-8s" % ("%.3f" % result.elapsed_time_of(exec))
          }.join(' ')
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
        puts "#{'%-16s' % 'name'} #{rest.map { |e| "%-8s" % e.name }.join(' ')}"
        results.each do |result|
          print '%-16s ' % result.name
          puts rest.map { |exec|
            "%-8s" % ("%.3f" % (result.elapsed_time_of(exec) / result.elapsed_time_of(compared)))
          }.join(' ')
        end
        puts
      end
    end
  end
end
