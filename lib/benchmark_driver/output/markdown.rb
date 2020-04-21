class BenchmarkDriver::Output::Markdown
  NAME_LENGTH = 8

  # @param [Array<BenchmarkDriver::Metric>] metrics
  # @param [Array<BenchmarkDriver::Job>] jobs
  # @param [Array<BenchmarkDriver::Context>] contexts
  def initialize(metrics:, jobs:, contexts:)
    @metrics = metrics
    @context_names = contexts.map(&:name)
    @name_length = jobs.map(&:name).map(&:size).max
  end

  def with_warmup(&block)
    without_stdout_buffering do
      $stdout.print 'warming up'
      block.call
    end
  ensure
    $stdout.puts
  end

  def with_benchmark(&block)
    @with_benchmark = true
    without_stdout_buffering do
      # Show header
      $stdout.puts "# #{@metrics.first.name} (#{@metrics.first.unit})\n\n"

      # Show executable names
      $stdout.print("|#{' ' * @name_length}  ")
      @context_names.each do |context_name|
        $stdout.printf("|%*s", NAME_LENGTH, context_name) # same size as humanize
      end
      $stdout.puts('|')

      # Show header separator
      $stdout.print("|:#{'-' * (@name_length - 1)}--")
      @context_names.each do |context_name|
        length = [context_name.length, NAME_LENGTH].max
        $stdout.print("|#{'-' * (length - 1)}:") # same size as humanize
      end
      $stdout.puts('|')

      block.call
    end
  rescue
    @with_benchmark = false
  end

  # @param [BenchmarkDriver::Job] job
  def with_job(job, &block)
    if @with_benchmark
      $stdout.printf("|%-*s  ", @name_length, job.name)
    end
    block.call
  ensure
    if @with_benchmark
      $stdout.puts('|')
    end
  end

  # @param [BenchmarkDriver::Context] context
  def with_context(context, &block)
    @context = context
    block.call
  end

  # @param [BenchmarkDriver::Result] result
  def report(result)
    if @with_benchmark
      length = [NAME_LENGTH, @context.name.length].max
      $stdout.printf("|%*s", length, humanize(result.values.fetch(@metrics.first)))
    else
      $stdout.print '.'
    end
  end

  private

  # benchmark_driver ouputs logs ASAP. This enables sync flag for it.
  def without_stdout_buffering
    sync, $stdout.sync = $stdout.sync, true
    yield
  ensure
    $stdout.sync = sync
  end

  def humanize(value)
    if BenchmarkDriver::Result::ERROR.equal?(value)
      return sprintf("%*s", NAME_LENGTH, 'ERROR')
    elsif value == 0.0
      return sprintf("%*.3f", NAME_LENGTH, 0.0)
    elsif value < 0
      raise ArgumentError.new("Negative value: #{value.inspect}")
    end

    scale = (Math.log10(value) / 3).to_i
    prefix = sprintf("%*.3f", NAME_LENGTH - 1, (value.to_f / (1000 ** scale)))
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
end
