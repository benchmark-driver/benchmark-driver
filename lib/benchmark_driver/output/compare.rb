# Compare output like benchmark-ips
class BenchmarkDriver::Output::Compare
  NAME_LENGTH = 20

  # @param [Array<BenchmarkDriver::Metric>] metrics
  # @param [Array<BenchmarkDriver::Job>] jobs
  # @param [Array<BenchmarkDriver::Context>] contexts
  def initialize(metrics:, jobs:, contexts:)
    @metrics = metrics
    @job_names = jobs.map(&:name)
    @context_names = contexts.map(&:name)
    @name_length = [@job_names.map(&:length).max, NAME_LENGTH].max
  end

  def with_warmup(&block)
    without_stdout_buffering do
      $stdout.puts 'Warming up --------------------------------------'
      # TODO: show exec name if it has multiple ones
      block.call
    end
  end

  def with_benchmark(&block)
    @job_context_result = Hash.new do |hash, job|
      hash[job] = {}
    end

    result = without_stdout_buffering do
      $stdout.puts 'Calculating -------------------------------------'
      if @context_names.size > 1
        $stdout.print(' ' * @name_length)
        @context_names.each do |context_name|
          $stdout.print(' %10s ' % context_name)
        end
        $stdout.puts
      end

      block.call
    end
    if @context_names.size > 1
      compare_executables
    elsif @job_names.size > 1
      compare_jobs
    end
    result
  end

  # @param [BenchmarkDriver::Job] job
  def with_job(job, &block)
    name = job.name
    if name.length > @name_length
      $stdout.puts(name)
    else
      $stdout.print("%#{@name_length}s" % name)
    end
    @job = name
    @job_results = []
    @job_contexts = []
    result = block.call
    $stdout.print(@metrics.first.unit)
    loop_count = @job_results.first.loop_count
    if loop_count && @job_results.all? { |r| r.loop_count == loop_count }
      $stdout.print(" - #{humanize(loop_count)} times")
      if @job_results.all? { |job_result| !job_result.duration.nil? }
        $stdout.print(" in")
        show_durations
      end
    end
    $stdout.puts
    result
  end

  # @param [BenchmarkDriver::Context] context
  def with_context(context, &block)
    @context = context
    @job_contexts << context
    block.call
  end

  # @param [BenchmarkDriver::Result] result
  def report(result)
    @job_results << result
    if defined?(@job_context_result)
      @job_context_result[@job][@context] = result
    end

    $stdout.print("#{humanize(result.values.values.first, [10, @context.name.length].max)} ")
  end

  private

  def show_durations
    @job_results.each do |result|
      $stdout.print(' %3.6fs' % result.duration)
    end

    # Show pretty seconds / clocks too. As it takes long width, it's shown only with a single executable.
    if @job_results.size == 1
      result = @job_results.first
      sec = result.duration
      iter = result.loop_count
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
    if BenchmarkDriver::Result::ERROR.equal?(value)
      return sprintf(" %*s", width, 'ERROR')
    elsif value == 0.0
      return sprintf(" %*.3f", width, 0.0)
    elsif value < 0
      raise ArgumentError.new("Negative value: #{value.inspect}")
    end

    scale = (Math.log10(value) / 3).to_i
    return sprintf("%*s", width, value.to_s) if scale < 0 # like 1.23e-04

    prefix = sprintf("%*.3f", width, (value.to_f / (1000 ** scale)))
    suffix =
      case scale
      when 1; 'k'
      when 2; 'M'
      when 3; 'G'
      when 4; 'T'
      when 5; 'Q'
      else # < 1000 or > 10^15, no scale or suffix
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
    results = @job_context_result.flat_map do |job, context_result|
      context_result.map { |context, result| Result.new(job: job, value: result.values.values.first, context: context) }
    end
    show_results(results, show_context: false)
  end

  def compare_executables
    $stdout.puts "\nComparison:"

    @job_context_result.each do |job, context_result|
      $stdout.printf("%*s\n", @name_length + 2 + 11, job)
      results = context_result.flat_map do |context, result|
        result.values.values.map { |value| Result.new(job: job, value: value, context: context) }
      end
      show_results(results, show_context: true)
    end
  end

  def show_slower(better_result, worse_result)
    top = worse_result.value
    bottom = better_result.value
    top, bottom = bottom, top if @metrics.first.larger_better

    unless BenchmarkDriver::Result::ERROR.equal?(bottom)
      ratio = top / bottom
      sprintf("- %.2fx  %s", ratio, @metrics.first.worse_word)
    end
  end

  # @param [Array<BenchmarkDriver::Output::Compare::Result>] results
  # @param [TrueClass,FalseClass] show_context
  def show_results(results, show_context:)
    results = results.sort_by do |result|
      if @metrics.first.larger_better
        -result.value
      else
        result.value
      end
    end

    first = results.first
    results.each do |result|
      slower = show_slower(first, result) if result != first
      if show_context
        name = result.context.name
      else
        name = result.job
      end
      $stdout.printf("%*s: %11.1f %s %s\n", @name_length, name, result.value, @metrics.first.unit, slower)
    end
    $stdout.puts
  end

  Result = ::BenchmarkDriver::Struct.new(:job, :value, :context)
end
