class Benchmark::Output::ExecutionTime
  # @param [Array<Benchmark::Driver::Configuration::Job>] jobs - not used
  # @param [Benchmark::Driver::Configuration::OutputOptions] options
  def initialize(jobs:, options:)
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
    $stdout.puts "\nbenchmark results:"
    $stdout.print("%-#{@name_length}s  " % 'name')
    $stdout.puts 'ruby' # TODO: print multiple rubies
  end

  # @param [String] name
  def running(name)
    $stdout.print("%-#{@name_length}s  " % name)
  end

  # @param [Benchmark::Driver::BenchmarkResult] result
  def benchmark_stats(result)
    $stdout.puts('%.3fs' % result.duration)
  end

  def finish
    # compare is not implemented yet
  end
end
