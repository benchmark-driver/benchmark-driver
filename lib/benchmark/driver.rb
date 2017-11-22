require 'benchmark'
require 'benchmark/driver/benchmark_metrics'
require 'benchmark/driver/benchmark_result'
require 'benchmark/driver/benchmark_root'
require 'benchmark/driver/benchmark_script'
require 'benchmark/driver/executable'
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
end
