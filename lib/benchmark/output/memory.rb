class Benchmark::Output::Memory
  # This class requires runner to measure following fields in `Benchmark::Driver::BenchmarkResult` to show output.
  REQUIRED_FIELDS = [:max_rss]

  # @param [Array<Benchmark::Driver::Configuration::Job>] jobs
  # @param [Array<Benchmark::Driver::Configuration::Executable>] executables
  # @param [Benchmark::Driver::Configuration::OutputOptions] options
  def initialize(jobs:, executables:, options:)
    @jobs = jobs
    @executables = executables
    @options = options
    @name_length = jobs.map { |j| j.name.size }.max
  end

  def start_warming
    $stdout.print 'warming up...'
  end

  # @param [String] name
  def warming(name)
    # noop
  end

  # @param [Benchmark::Driver::BenchmarkResult] result
  def warmup_stats(result)
    $stdout.print '.'
  end

  def start_running
    $stdout.puts if @jobs.any?(&:warmup_needed?)
    $stdout.puts 'max resident memory (KB):'
    $stdout.print("%-#{@name_length}s  " % 'ruby')
    @executables.each do |executable|
      $stdout.print('%-6s  ' % executable.name)
    end
    $stdout.puts
  end

  # @param [String] name
  def running(name)
    $stdout.print("%-#{@name_length}s  " % name)
    @ran_num = 0
  end

  # @param [Benchmark::Driver::BenchmarkResult] result
  def benchmark_stats(result)
    $stdout.print('%-6d  ' % result.max_rss)
    @ran_num += 1
    if @ran_num == @executables.size
      $stdout.puts
    end
  end

  def finish
    # compare is not implemented yet
  end
end
