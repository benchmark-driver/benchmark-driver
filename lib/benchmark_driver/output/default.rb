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

      # @param [BenchmarkDriver::Metrics] metrics
      def report(metrics)
        $stdout.print("#{humanize(metrics.value, [10, metrics.executable.name.length].max)} ")
      end

      # @param [BenchmarkDriver::Metrics] metrics
      def with_benchmark(metrics_type, &block)
        @metrics_type = metrics_type
        without_stdout_buffering do
          start_running
          block.call
        end
      ensure
        @metrics_type = nil
      end

      # @param [BenchmarkDriver::*::Job] job
      def with_job(job, &block)
        if job.name.length > NAME_LENGTH
          $stdout.puts(job.name)
        else
          $stdout.print("%#{NAME_LENGTH}s" % job.name)
        end
        block.call
      ensure
        $stdout.puts(@metrics_type.unit)
      end

      private

      def start_running
        $stdout.puts 'Calculating -------------------------------------'
        if @executables.size > 1
          $stdout.print(' ' * NAME_LENGTH)
          @executables.each do |executable|
            $stdout.print(' %10s ' % executable.name)
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

      def humanize(value, width = 10)
        scale = (Math.log10(value) / 3).to_i
        prefix = "%#{width}.3f" % (value.to_f / (1000 ** scale))
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
  end
end
