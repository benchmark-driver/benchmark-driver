class Benchmark::Output::Ips
  NAME_LENGTH = 20

  # @param [Array<Benchmark::Driver::Configuration::Job>] jobs
  # @param [Array<Benchmark::Driver::Configuration::Executable>] executables
  # @param [Benchmark::Driver::Configuration::OutputOptions] options
  def initialize(jobs:, executables:, options:)
    @jobs        = jobs
    @executables = executables
    @options     = options
    @results     = []
    @name_by_result = {}
  end

  def start_warming
    $stdout.puts 'Warming up --------------------------------------'
  end

  # @param [String] name
  def warming(name)
    if name.length > NAME_LENGTH
      $stdout.puts(name)
    else
      $stdout.print("%#{NAME_LENGTH}s" % name)
    end
  end

  # @param [Benchmark::Driver::BenchmarkResult] result
  def warmup_stats(result)
    $stdout.puts "#{humanize(result.ip100ms)} i/100ms"
  end

  def start_running
    $stdout.puts 'Calculating -------------------------------------'
    if @executables.size > 1
      $stdout.print(' ' * NAME_LENGTH)
      @executables.each do |executable|
        $stdout.print(" %10s " % executable.name)
      end
      $stdout.puts
    end
  end

  def running(name)
    warming(name)
    @row_results = []
  end

  # @param [Benchmark::Driver::BenchmarkResult] result
  def benchmark_stats(result)
    executable = @executables[@row_results.size]
    $stdout.print("#{humanize(result.ips, [10, executable.name.length].max)} ")

    @results << result
    @row_results << result
    if @row_results.size == @executables.size
      $stdout.print("i/s - #{humanize(result.iterations)} in")
      @row_results.each do |r|
        $stdout.print(" %3.6fs" % r.duration)
      end
      $stdout.puts
    end

    @name_by_result[result] = executable.name
  end

  def finish
    if @results.size > 1 && @options.compare
      compare
    end
  end

  private

  def humanize(value, width = 10)
    scale = (Math.log10(value) / 3).to_i
    suffix =
      case scale
      when 1; 'k'
      when 2; 'M'
      when 3; 'B'
      when 4; 'T'
      when 5; 'Q'
      else # < 1000 or > 10^15, no scale or suffix
        scale = 0
        ' '
      end
    "%#{width}.3f#{suffix}" % (value.to_f / (1000 ** scale))
  end

  def compare
    $stdout.puts("\nComparison:")
    results = @results.sort_by { |r| -r.ips }
    first   = results.first

    results.each do |result|
      if result == first
        slower = ''
      else
        slower = '- %.2fx  slower' % (first.ips / result.ips)
      end

      name = result.job.name
      if @executables.size > 1
        name = "#{name} (#{@name_by_result.fetch(result)})"
      end
      $stdout.puts("%#{NAME_LENGTH}s: %11.1f i/s #{slower}" % [name, result.ips])
    end
    $stdout.puts
  end
end
