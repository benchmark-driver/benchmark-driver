class BenchmarkDriver::Output::Record
  # @param [Array<BenchmarkDriver::Metric>] metrics
  # @param [Array<String>] job_names
  # @param [Array<String>] context_names
  def initialize(metrics:, job_names:, context_names:)
    @metrics = metrics
    @job_warmup_context_result = Hash.new do |h1, job|
      h1[job] = Hash.new do |h2, warmup|
        h2[warmup] = Hash.new do |h3, context|
          h3[context] = {}
        end
      end
    end
  end

  def with_warmup(&block)
    $stdout.print 'warming up'
    block.call
  ensure
    $stdout.puts
  end

  def with_benchmark(&block)
    @with_benchmark = true
    $stdout.print 'benchmarking'
    block.call
  ensure
    $stdout.puts
    @with_benchmark = false
    save_record
  end

  # @param [BenchmarkDriver::Job] job
  def with_job(job, &block)
    @job = job
    block.call
  end

  # @param [BenchmarkDriver::Context] context
  def with_context(context, &block)
    @context = context
    block.call
  end

  # @param [BenchmarkDriver::Result] result
  def report(result)
    $stdout.print '.'
    @job_warmup_context_result[@job][!@with_benchmark][@context] = result
  end

  private

  def save_record
    jobs = @benchmark_metrics
    yaml = {
      'type' => 'recorded',
      'job_warmup_context_result' => @job_warmup_context_result,
      'metrics' => @metrics,
    }.to_yaml
    File.write('benchmark_driver.record.yml', yaml)
  end
end
