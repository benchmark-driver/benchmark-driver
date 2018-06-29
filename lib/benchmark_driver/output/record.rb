class BenchmarkDriver::Output::Record
  # @param [BenchmarkDriver::Metrics::Type] metrics_type
  attr_writer :metrics_type

  # @param [Array<String>] jobs
  # @param [Array<BenchmarkDriver::Config::Executable>] executables
  def initialize(jobs:, executables:)
    @executables = executables
    @metrics_by_job = Hash.new do |h1, k1|
      h1[k1] = Hash.new { |h2, k2| h2[k2] = [] }
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

  # @param [String] job_name
  def with_job(job_name, &block)
    @current_job = job_name
    block.call
  end

  # @param [BenchmarkDriver::Metrics] metrics
  def report(metrics)
    $stdout.print '.'
    if @with_benchmark
      @metrics_by_job[@current_job][:benchmark] << metrics
    else
      @metrics_by_job[@current_job][:warmup] << metrics
    end
  end

  private

  def save_record
    jobs = @benchmark_metrics
    yaml = {
      'type' => 'recorded',
      'metrics_by_job' => @metrics_by_job,
      'metrics_type' => @metrics_type,
    }.to_yaml
    File.write('benchmark_driver.record.yml', yaml)
  end
end
