# Output like benchmark-ips
module BenchmarkDriver
  module Output
    class Default
      NAME_LENGTH = 20

      # @param [Array<BenchmarkDriver::*::Job>] jobs
      # @param [Array<BenchmarkDriver::Config::Executable>] executables
      def initialize(jobs:, executables:)
        @jobs = jobs
        @executables = executables
      end

      # @param [BenchmarkDriver::Metric] metric
      def report(metric)
        # TODO: implement
      end

      def with_benchmark(&block)
        without_stdout_buffering do
          start_running
          block.call
        end
      end

      # @param [BenchmarkDriver::*::Job] job
      def with_job(job, &block)
        if job.name.length > NAME_LENGTH
          $stdout.puts(job.name)
        else
          $stdout.print("%#{NAME_LENGTH}s" % job.name)
        end
        @job_metrics = []
        block.call
      ensure
        $stdout.puts
      end

      private

      def start_running
        $stdout.puts 'Calculating -------------------------------------'
        if @executables.size > 1
          $stdout.print(' ' * NAME_LENGTH)
          @executables.each do |executable|
            $stdout.print(" %10s " % executable.name)
          end
          $stdout.puts
        end
      end

      # benchmark_driver ouputs logs ASAP. This enables sync flag for it.
      def without_stdout_buffering
        sync, $stdout.sync = $stdout.sync, true
        yield
      ensure
        $stdout.sync = sync
      end
    end
  end
end
