class Benchmark::Output::Ips
  NAME_LENGTH = 20

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
  end

  alias_method :running, :warming

  # @param [Benchmark::Driver::BenchmarkResult] result
  def benchmark_stats(result)
    $stdout.puts("#{humanize(result.ips)} i/s - #{humanize(result.iterations)} in %3.6fs" % result.duration)
  end

  private

  def humanize(value)
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
    "%10.3f#{suffix}" % (value.to_f / (1000 ** scale))
  end
end
