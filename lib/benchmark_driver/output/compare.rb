# Compare output like benchmark-ips
class BenchmarkDriver::Output::Compare
  NAME_LENGTH = 20

  # @param [Array<BenchmarkDriver::Metric>] metrics
  attr_writer :metrics

  # @param [Array<String>] job_names
  # @param [Array<String>] context_names
  def initialize(job_names:, context_names:)
    @job_names = job_names
    @context_names = context_names
  end

  def with_warmup(&block)
    without_stdout_buffering do
      $stdout.puts 'Warming up --------------------------------------'
      # TODO: show exec name if it has multiple ones
      block.call
    end
  end

  def with_benchmark(&block)
    @job_context_values = Hash.new do |h1, k1|
      h1[k1] = Hash.new { |h2, k2| h2[k2] = [] }
    end

    without_stdout_buffering do
      $stdout.puts 'Calculating -------------------------------------'
      if @context_names.size > 1
        $stdout.print(' ' * NAME_LENGTH)
        @context_names.each do |context_name|
          $stdout.print(' %10s ' % context_name)
        end
        $stdout.puts
      end

      block.call
    end
  ensure
    if @context_names.size > 1
      compare_executables
    elsif @job_names.size > 1
      compare_jobs
    end
  end

  # @param [BenchmarkDriver::Job] job
  def with_job(job, &block)
    name = job.name
    if name.length > NAME_LENGTH
      $stdout.puts(name)
    else
      $stdout.print("%#{NAME_LENGTH}s" % name)
    end
    @job = name
    @job_contexts = []
    block.call
  ensure
    $stdout.print(@metrics.first.unit)
    loop_count = @job_contexts.first.loop_count
    if loop_count && @job_contexts.all? { |c| c.loop_count == loop_count }
      $stdout.print(" - #{humanize(loop_count)} times")
      if @job_contexts.all? { |context| !context.duration.nil? }
        $stdout.print(" in")
        show_durations
      end
    end
    $stdout.puts
  end

  # @param [BenchmarkDriver::Context] context
  def with_context(context, &block)
    @context = context
    @job_contexts << context
    block.call
  end

  # @param [Float] value
  # @param [BenchmarkDriver::Metric] metic
  def report(value:, metric:)
    if defined?(@job_context_values)
      @job_context_values[@job][@context] << value
    end

    $stdout.print("#{humanize(value, [10, @context.name.length].max)} ")
  end

  private

  def show_durations
    @job_contexts.each do |context|
      $stdout.print(' %3.6fs' % context.duration)
    end

    # Show pretty seconds / clocks too. As it takes long width, it's shown only with a single executable.
    if @job_contexts.size == 1
      context = @job_contexts.first
      sec = context.duration
      iter = context.loop_count
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
    results = @job_context_values.flat_map do |job, context_values|
      context_values.map { |context, values| Result.new(job: job, value: values.first, executable: context.executable) }
    end
    show_results(results, show_executable: false)
  end

  def compare_executables
    $stdout.puts "\nComparison:"

    @job_context_values.each do |job, context_values|
      $stdout.puts("%#{NAME_LENGTH + 2 + 11}s" % job)
      results = context_values.flat_map do |context, values|
        values.map { |value| Result.new(job: job, value: value, executable: context.executable) }
      end
      show_results(results, show_executable: true)
    end
  end

  # @param [Array<BenchmarkDriver::Output::Compare::Result>] results
  # @param [TrueClass,FalseClass] show_executable
  def show_results(results, show_executable:)
    results = results.sort_by do |result|
      if @metrics.first.larger_better
        -result.value
      else
        result.value
      end
    end

    first = results.first
    results.each do |result|
      if result != first
        if @metrics.first.larger_better
          ratio = (first.value / result.value)
        else
          ratio = (result.value / first.value)
        end
        slower = "- %.2fx  #{@metrics.first.worse_word}" % ratio
      end
      if show_executable
        name = result.executable.name
      else
        name = result.job
      end
      $stdout.puts("%#{NAME_LENGTH}s: %11.1f %s #{slower}" % [name, result.value, @metrics.first.unit])
    end
    $stdout.puts
  end

  Result = ::BenchmarkDriver::Struct.new(:job, :value, :executable)
end
