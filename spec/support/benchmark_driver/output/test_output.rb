class BenchmarkDriver::Output::TestOutput < BenchmarkDriver::BulkOutput
  # @param [Hash{ BenchmarkDriver::Job => Hash{ BenchmarkDriver::Context => BenchmarkDriver::Result } }] result
  # @param [Array<BenchmarkDriver::Metric>] metrics
  def bulk_output(job_context_result:, metrics:)
    job_context_result.each do |job, context_result|
      context_result.each do |context, result|
        result.values.each do |metric, value|
          puts "#{job.name}: #{context.name}: #{metric.name}: #{value}"
        end
      end
    end
  end
end
