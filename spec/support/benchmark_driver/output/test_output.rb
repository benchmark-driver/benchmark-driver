class BenchmarkDriver::Output::TestOutput < BenchmarkDriver::BulkOutput
  # @param [Hash{ BenchmarkDriver::Job => Hash{ BenchmarkDriver::Context => { BenchmarkDriver::Metric => Float } } }] result
  # @param [Array<BenchmarkDriver::Metric>] metrics
  def bulk_output(result:, metrics:)
    result.each do |job, context_metric_value|
      context_metric_value.each do |context, metric_value|
        metric_value.each do |metric, value|
          puts "#{job.name}: #{context.name}: #{metric.name}: #{value}"
        end
      end
    end
  end
end
