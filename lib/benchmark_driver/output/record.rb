class BenchmarkDriver::Output::Record
  # @param [Array<BenchmarkDriver::Metric>] metrics
  attr_writer :metrics

  # @param [Array<String>] job_names
  # @param [Array<String>] context_names
  def initialize(job_names:, context_names:)
    @job_warmup_context_metric_value = Hash.new do |h1, k1|
      h1[k1] = Hash.new do |h2, k2|
        h2[k2] = Hash.new do |h3, k3|
          h3[k3] = {}
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
    @job = job.name
    block.call
  end

  # @param [BenchmarkDriver::Context] context
  def with_context(context, &block)
    @context = context
    block.call
  end

  # @param [Float] value
  # @param [BenchmarkDriver::Metric] metic
  def report(value:, metric:)
    $stdout.print '.'
    @job_warmup_context_metric_value[@job][!@with_benchmark][@context][metric] = value
  end

  private

  def save_record
    jobs = @benchmark_metrics
    yaml = {
      'type' => 'recorded',
      'job_warmup_context_metric_value' => @job_warmup_context_metric_value,
      'metrics' => @metrics,
    }.to_yaml
    File.write('benchmark_driver.record.yml', yaml)
  end
end
