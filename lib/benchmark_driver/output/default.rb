# Output like benchmark-ips
module BenchmarkDriver
  module Output
    class Default
      NAME_LENGTH = 20

      # @param [Array<BenchmarkDriver::*::Job>] jobs
      # @param [Array<BenchmarkDriver::Config::Executable>] executables
      # @param [BenchmarkDriver::Metrics::Type] metrics_type
      def initialize(jobs:, executables:, metrics_type:)
        @jobs = jobs
        @executables = executables
        @metrics_type = metrics_type
      end

      # @param [BenchmarkDriver::Metrics] metrics
      def with_warmup(&block)
        without_stdout_buffering do
          $stdout.puts 'Warming up --------------------------------------'
          block.call
        end
      end

      # @param [BenchmarkDriver::Metrics] metrics
      def with_benchmark(&block)
        without_stdout_buffering do
          $stdout.puts 'Calculating -------------------------------------'
          if @executables.size > 1
            $stdout.print(' ' * NAME_LENGTH)
            @executables.each do |executable|
              $stdout.print(' %10s ' % executable.name)
            end
            $stdout.puts
          end

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
        block.call
      ensure
        $stdout.puts(@metrics_type.unit)
      end

      # @param [BenchmarkDriver::Metrics] metrics
      def report(metrics)
        $stdout.print("#{humanize(metrics.value, [10, metrics.executable.name.length].max)} ")
      end

      private

      # benchmark_driver ouputs logs ASAP. This enables sync flag for it.
      def without_stdout_buffering
        sync, $stdout.sync = $stdout.sync, true
        yield
      ensure
        $stdout.sync = sync
      end

      def humanize(value, width = 10)
        if value < 0
          raise ArgumentError.new("Negative value: #{value.inspect}")
        end

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
