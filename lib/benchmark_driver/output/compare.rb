# Compare output like benchmark-ips
class BenchmarkDriver::Output::Compare
  NAME_LENGTH = 20

  # @param [BenchmarkDriver::Metrics::Type] metrics_type
  attr_writer :metrics_type

  # @param [Array<String>] jobs
  # @param [Array<BenchmarkDriver::Config::Executable>] executables
  def initialize(jobs:, executables:)
    @jobs = jobs
    @executables = executables
  end

  def with_warmup(&block)
    without_stdout_buffering do
      $stdout.puts 'Warming up --------------------------------------'
      # TODO: show exec name if it has multiple ones
      block.call
    end
  end

  def with_benchmark(&block)
    @metrics_by_job = Hash.new { |h, k| h[k] = [] }

    without_stdout_buffering do
      $stdout.puts 'Calculating -------------------------------------'
      if @executables.size > 1
        $stdout.print(' ' * NAME_LENGTH)
        @executables.each do |executable|
          $stdout.print(' %10s ' % executable.name)
        end
        $stdout.puts
      end

      block.call
    end
  ensure
    if @executables.size > 1
      compare_executables
    elsif @jobs.size > 1
      compare_jobs
    end
  end

  # @param [BenchmarkDriver::Job] job
  def with_job(job, &block)
    name = job.name
    if name
      $stdout.puts(name)
    else
      $stdout.print("%#{NAME_LENGTH}s" % name)
    end
    @current_job = name
    @job_metrics = []
    block.call
  ensure
    $stdout.print(@metrics_type.unit)
    # if job.respond_to?(:loop_count) && job.loop_count
    #   $stdout.print(" - #{humanize(job.loop_count)} times")
    #   if @job_metrics.all? { |metrics| metrics.duration }
    #     $stdout.print(" in")
    #     show_durations
    #   end
    # end
    $stdout.puts
  end

  # @param [BenchmarkDriver::Context] context
  def with_context(context, &block)
    @context = context
    block.call
  end

  # @param [BenchmarkDriver::Metrics] metrics
  def report(metrics)
    if defined?(@metrics_by_job)
      @metrics_by_job[@current_job] << metrics
    end

    @job_metrics << metrics
    $stdout.print("#{humanize(metrics.value, [10, @context.name.length].max)} ")
  end

  private

  def show_durations
    @job_metrics.each do |metrics|
      $stdout.print(' %3.6fs' % metrics.duration)
    end

    # Show pretty seconds / clocks too. As it takes long width, it's shown only with a single executable.
    if @job_metrics.size == 1
      metrics = @job_metrics.first
      sec = metrics.duration
      iter = @current_job.loop_count
      if File.exist?('/proc/cpuinfo') && (clks = estimate_clock(sec, iter)) < 1_000
        $stdout.print(" (#{pretty_sec(sec, iter)}/i, #{clks}clocks/i)")
      else
        $stdout.print(" (#{pretty_sec(sec, iter)}/i)")
      end
    end
  end

  # benchmark_driver ouputs logs ASAP. This enables sync flag for it.
  def without_stdout_buffering
    sync, $stdout.sync = $stdout.sync, true
    yield
  ensure
    $stdout.sync = sync
  end

  def humanize(value, width = 10)
    if value <= 0
      raise ArgumentError.new("Non positive value: #{value.inspect}")
    end

    scale = (Math.log10(value) / 3).to_i
    return "%#{width}s" % value.to_s if scale < 0 # like 1.23e-04

    prefix = "%#{width}.3f" % (value.to_f / (1000 ** scale))
    suffix =
      case scale
      when 1; 'k'
      when 2; 'M'
      when 3; 'G'
      when 4; 'T'
      when 5; 'Q'
      else # < 1000 or > 10^15, no scale or suffix
        scale = 0
        return " #{prefix}"
      end
    "#{prefix}#{suffix}"
  end

  def pretty_sec(sec, iter)
    r = Rational(sec, iter)
    case
    when r >= 1
      "#{'%3.2f' % r.to_f}s"
    when r >= 1/1000r
      "#{'%3.2f' % (r * 1_000).to_f}ms"
    when r >= 1/1000_000r
      "#{'%3.2f' % (r * 1_000_000).to_f}μs"
    else
      "#{'%3.2f' % (r * 1_000_000_000).to_f}ns"
    end
  end

  def estimate_clock sec, iter
    hz = File.read('/proc/cpuinfo').scan(/cpu MHz\s+:\s+([\d\.]+)/){|(f)| break hz = Rational(f.to_f) * 1_000_000}
    r = Rational(sec, iter)
    Integer(r/(1/hz))
  end

  def compare_jobs
    $stdout.puts "\nComparison:"
    results = @metrics_by_job.map { |job, metrics| Result.new(job: job, metrics: metrics.first) }
    show_results(results, show_executable: false)
  end

  def compare_executables
    $stdout.puts "\nComparison:"

    @metrics_by_job.each do |job, metrics|
      $stdout.puts("%#{NAME_LENGTH + 2 + 11}s" % job)
      results = metrics.map { |metrics| Result.new(job: job, metrics: metrics) }
      show_results(results, show_executable: true)
    end
  end

  # @param [Array<BenchmarkDriver::Output::Compare::Result>] results
  # @param [TrueClass,FalseClass] show_executable
  def show_results(results, show_executable:)
    results = results.sort_by do |result|
      if @metrics_type.larger_better
        -result.metrics.value
      else
        result.metrics.value
      end
    end

    first = results.first
    results.each do |result|
      if result != first
        if @metrics_type.larger_better
          ratio = (first.metrics.value / result.metrics.value)
        else
          ratio = (result.metrics.value / first.metrics.value)
        end
        slower = "- %.2fx  #{@metrics_type.worse_word}" % ratio
      end
      if show_executable
        name = result.metrics.executable.name
      else
        name = result.job
      end
      $stdout.puts("%#{NAME_LENGTH}s: %11.1f %s #{slower}" % [name, result.metrics.value, @metrics_type.unit])
    end
    $stdout.puts
  end

  Result = ::BenchmarkDriver::Struct.new(:job, :metrics)
end
