require 'benchmark'
require 'benchmark/driver/version'
require 'benchmark/output'
require 'tempfile'

class Benchmark::Driver
  MEASURE_TYPES = %w[loop_count ips]
  DEFAULT_LOOP_COUNT = 100_000
  DEFAULT_IPS_DURATION = 1

  # @param [String] measure_type - "loop_count"|"ips"
  # @param [Integer,nil] measure_num - Loop count for "loop_type", duration seconds for "ips"
  # @param [Array<String>] execs - ["path1", "path2"] or `["ruby1::path1", "ruby2::path2"]`
  # @param [Boolean] verbose
  def initialize(measure_type: 'loop_count', measure_num: nil, execs: ['ruby'], verbose: false)
    unless MEASURE_TYPES.include?(measure_type)
      abort "unsupported measure type: #{measure_type.dump}"
    end
    @measure_type = measure_type
    @measure_num = measure_num
    @execs = execs.map do |exec|
      name, path = exec.split('::', 2)
      Executable.new(name, path || name)
    end
    @verbose = verbose
  end

  # @param [Hash] root_hash
  def run(root_hash)
    root = BenchmarkRoot.new(Hash[root_hash.map { |k, v| [k.to_sym, v] }])

    results = root.benchmarks.map do |benchmark|
      metrics_by_exec = {}
      iterations = calc_iterations(@execs.first, benchmark)
      @execs.each do |exec|
        if @verbose
          puts "--- Running #{benchmark.name.dump} with #{exec.name.dump} #{iterations} times ---"
          puts "#{benchmark.benchmark_script(iterations)}\n"
        end
        elapsed_time = run_benchmark(exec, benchmark, iterations)
        metrics_by_exec[exec] = BenchmarkMetrics.new(iterations, elapsed_time)
      end
      BenchmarkResult.new(benchmark.name, metrics_by_exec)
    end
    puts if @verbose

    case @measure_type
    when 'loop_count'
      Benchmark::Output::ExecutionTime.report(@execs, results)
    when 'ips'
      Benchmark::Output::Ips.report(@execs, results)
    else
      raise "unexpected measure type: #{@measure_type.dump}"
    end
  end

  private

  # Estimate iterations to finish benchmark within `@duration`.
  def calc_iterations(exec, benchmark)
    case @measure_type
    when 'loop_count'
      @measure_num || benchmark.loop_count || DEFAULT_LOOP_COUNT
    when 'ips'
      # TODO: Change to try from 1, 10, 100 ...
      base = 1000
      time = run_benchmark(exec, benchmark, base)
      duration = @measure_num || DEFAULT_IPS_DURATION
      (duration / time * base).to_i
    else
      raise "unexpected measure type: #{@measure_type.dump}"
    end
  end

  def run_benchmark(exec, benchmark, iterations)
    # TODO: raise error if negative
    measure_script(exec.path, benchmark.benchmark_script(iterations)) -
      measure_script(exec.path, benchmark.overhead_script(iterations))
  end

  def measure_script(ruby, script)
    Tempfile.create(File.basename(__FILE__)) do |f|
      f.write(script)
      f.close

      cmd = "#{ruby} #{f.path}"
      Benchmark.measure { system(cmd, out: File::NULL) }.real
    end
  end

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

    def ips_of(exec)
      iterations_of(exec) / elapsed_time_of(exec)
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
end
