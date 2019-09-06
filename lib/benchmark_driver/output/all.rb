class BenchmarkDriver::Output::All
  NAME_LENGTH = 20
  CONTEXT_LENGTH = 20

  OPTIONS = {
    sort: ['--output-sort true|false', TrueClass, 'Sort all output or not (default: true)'],
  }

  # @param [Array<BenchmarkDriver::Metric>] metrics
  # @param [Array<BenchmarkDriver::Job>] jobs
  # @param [Array<BenchmarkDriver::Context>] contexts
  def initialize(metrics:, jobs:, contexts:, options:)
    @metrics = metrics
    @job_names = jobs.map(&:name)
    @context_names = contexts.map(&:name)
    @name_length = [@job_names.map(&:length).max, NAME_LENGTH].max
    @sort = options.fetch(:sort, true)
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
          $stdout.print(" %#{CONTEXT_LENGTH}s " % context_name)
        end
        $stdout.puts
      end

      block.call
    end
    result
  end

  # @param [BenchmarkDriver::Job] job
  def with_job(job, &block)
    @job_name = "%#{@name_length}s" % job.name
    $stdout.print(@job_name)
    @context_values = {}
    block.call
  end

  # @param [BenchmarkDriver::Context] context
  def with_context(context, &block)
    @context = context
    block.call
  end

  # @param [BenchmarkDriver::Result] result
  def report(result)
    if result.all_values.nil? || !defined?(@context_values)
      $stdout.puts(" %#{[CONTEXT_LENGTH, @context.name.length].max}s " % result.values.values.first.to_s)
      return
    end

    num_values = result.all_values.values.first.size
    if @context_values.empty?
      print("\r")
    else
      print("\e[#{num_values}F")
    end
    @context_values[@context] = result.all_values.values.first
    if @sort
      @context_values[@context] = @context_values[@context].sort
    end

    precision = result.values.values.first.to_s.sub(/\A\d+\./, '').length
    num_values.times do |i|
      if i == 0
        $stdout.print(@job_name)
      else
        print(" " * [@job_name.length, NAME_LENGTH].max)
      end

      @context_values.each do |context, values|
        $stdout.print(" %#{[CONTEXT_LENGTH, context.name.length].max}.#{precision}f " % values[i])
      end
      (@context_names - @context_values.keys.map(&:name)).each do |context_name|
        print(" " * ([CONTEXT_LENGTH, context_name.length].max + 2))
      end

      if i == 0
        $stdout.puts(@metrics.first.unit)
      else
        $stdout.puts
      end
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
end
