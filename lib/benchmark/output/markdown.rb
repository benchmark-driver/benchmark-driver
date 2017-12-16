class Benchmark::Output::Markdown
  # This class requires runner to measure following fields in `Benchmark::Driver::BenchmarkResult` to show output.
  REQUIRED_FIELDS = [:real]

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

    $stdout.print("|#{' ' * @name_length}|")
    @executables.each do |executable|
      $stdout.print('%-10s |' % executable.name)
    end
    $stdout.puts

    $stdout.print("|:#{'-' * (@name_length-1)}|")
    @executables.each do |executable|
      $stdout.print(":#{'-' * 10}|")
    end
    $stdout.puts
  end

  # @param [String] name
  def running(name)
    $stdout.print("|%-#{@name_length}s|" % name)
    @ran_num = 0
  end

  # @param [Benchmark::Driver::BenchmarkResult] result
  def benchmark_stats(result)
    if @options.compare
      if @ran_num == 0
        @base_real = result.real
        $stdout.print('%-10.2f |' % 1)
      else
        $stdout.print('%-10.2f |' % (@base_real / result.real))
      end
    else
      $stdout.print('%-10.3f |' % result.real)
    end

    @ran_num += 1
    if @ran_num == @executables.size
      $stdout.puts
    end
  end

  def finish
    # compare is done in table
  end
end
