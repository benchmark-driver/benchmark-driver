class BenchmarkDriver::Output::Simple
  NAME_LENGTH = 10

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
      $stdout.puts "#{@metrics.first.name} (#{@metrics.first.unit}):"

      # Show executable names
      if @context_names.size > 1
        $stdout.print("#{' ' * @name_length}  ")
        @context_names.each do |context_name|
          $stdout.print("%#{NAME_LENGTH}s  " % context_name)
        end
        $stdout.puts
      end

      block.call
    end
  ensure
    @with_benchmark = false
  end

  # @param [BenchmarkDriver::Job] job
  def with_job(job, &block)
    if @with_benchmark
      $stdout.print("%-#{@name_length}s  " % job.name)
    end
    block.call
  ensure
    if @with_benchmark
      $stdout.puts
    end
  end

  # @param [BenchmarkDriver::Context] context
  def with_context(context, &block)
    block.call
  end

  # @param [BenchmarkDriver::Result] result
  def report(result)
    if @with_benchmark
      $stdout.print("%#{NAME_LENGTH}s  " % humanize(result.values.fetch(@metrics.first)))
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
      return " %#{NAME_LENGTH}s" % 'ERROR'
    elsif value == 0.0
      return " %#{NAME_LENGTH}.3f" % 0.0
    elsif value < 0
      raise ArgumentError.new("Negative value: #{value.inspect}")
    end

    scale = (Math.log10(value) / 3).to_i
    prefix = "%#{NAME_LENGTH}.3f" % (value.to_f / (1000 ** scale))
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
