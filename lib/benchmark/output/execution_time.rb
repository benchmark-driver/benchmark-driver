class Benchmark::Output::ExecutionTime
  # @param [Array<Benchmark::Driver::Configuration::Job>] jobs - not used
  # @param [Array<Benchmark::Driver::Configuration::Executable>] executables
  # @param [Benchmark::Driver::Configuration::OutputOptions] options
  def initialize(jobs:, executables:, options:)
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
    $stdout.puts "\nbenchmark results (s):"
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
    $stdout.print('%-6.3f  ' % result.duration)
    @ran_num += 1
    if @ran_num == @executables.size
      $stdout.puts
    end
  end

  def finish
    # compare is not implemented yet
  end
end
