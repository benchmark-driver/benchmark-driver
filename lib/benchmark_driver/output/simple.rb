class BenchmarkDriver::Output::Simple
  NAME_LENGTH = 8

  # @param [BenchmarkDriver::Metrics::Type] metrics_type
  attr_writer :metrics_type

  # @param [Array<String>] jobs
  # @param [Array<BenchmarkDriver::Config::Executable>] executables
  def initialize(jobs:, executables:)
    @executables = executables
    @name_length = jobs.map(&:size).max
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
      $stdout.puts "benchmark results (#{@metrics_type.unit}):"

      # Show executable names
      if @executables.size > 1
        $stdout.print("#{' ' * @name_length}  ")
        @executables.each do |executable|
          $stdout.print("%#{NAME_LENGTH}s  " % executable.name)
        end
        $stdout.puts
      end

      block.call
    end
  rescue
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

  # @param [Float] value
  # @param [BenchmarkDriver::Metric] metic
  def report(value:, metric:)
    if @with_benchmark
      $stdout.print("%#{NAME_LENGTH}s  " % humanize(value))
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
    if value < 0
      raise ArgumentError.new("Negative value: #{value.inspect}")
    end

    scale = (Math.log10(value) / 3).to_i
    prefix = "%6.3f" % (value.to_f / (1000 ** scale))
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
end
