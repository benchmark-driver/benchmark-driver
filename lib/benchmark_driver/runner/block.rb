require 'benchmark_driver/default_job'
require 'benchmark_driver/default_job_parser'

class BenchmarkDriver::Runner::Block < BenchmarkDriver::Runner::Ips
  METRIC = BenchmarkDriver::Metric.new(name: 'Iteration per second', unit: 'i/s')

  # JobParser returns this, `BenchmarkDriver::Runner.runner_for` searches "*::Job"
  Job = Class.new(BenchmarkDriver::DefaultJob)

  # Dynamically fetched and used by `BenchmarkDriver::JobParser.parse`
  JobParser = BenchmarkDriver::DefaultJobParser.for(klass: Job, metrics: [METRIC]).extend(Module.new{
    def parse(*)
      jobs = super
      jobs.map do |job|
        job = job.dup
        job.prelude = "#{job.prelude}\n__bmdv_script_block = proc { #{job.script} }"
        job.script = '__bmdv_script_block.call'
        job
      end
    end
  })
end
