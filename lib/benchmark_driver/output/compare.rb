# Output like benchmark-ips
module BenchmarkDriver
  module Output
    class Compare
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
          # TODO: show exec name if it has multiple ones
          block.call
        end
      end

      # @param [BenchmarkDriver::Metrics] metrics
      def with_benchmark(&block)
        @metrics_by_job = Hash.new { |h, k| h[k] = [] }

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
      ensure
        if @executables.size == 1
          compare_jobs
        else
          compare_executables
        end
      end

      # @param [BenchmarkDriver::*::Job] job
      def with_job(job, &block)
        if job.name.length > NAME_LENGTH
          $stdout.puts(job.name)
        else
          $stdout.print("%#{NAME_LENGTH}s" % job.name)
        end
        @current_job = job
        @job_metrics = []
        block.call
      ensure
        $stdout.print(@metrics_type.unit)
        if job.loop_count && @job_metrics.all? { |metrics| metrics.duration }
          $stdout.print(" - #{humanize(job.loop_count)} in")
          show_durations
        end
        $stdout.puts
      end

      # @param [BenchmarkDriver::Metrics] metrics
      def report(metrics)
        if defined?(@metrics_by_job)
          @metrics_by_job[@current_job] << metrics
        end

        @job_metrics << metrics
        $stdout.print("#{humanize(metrics.value, [10, metrics.executable.name.length].max)} ")
      end

      private

      def show_durations
        @job_metrics.each do |metrics|
          $stdout.print(' %3.6fs' % metrics.duration)
          # TODO: show clocks again
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

      def compare_jobs
        $stdout.puts "\nComparison:"
        results = @metrics_by_job.map { |job, metrics| Result.new(job: job, metrics: metrics.first) }
        results.sort_by! do |result|
          if @metrics_type.larger_better
            -result.metrics.value
          else
            result.metrics.value
          end
        end

        first = results.first
        results.each do |result|
          if result == first
            slower = ''
          else
            slower = '- %.2fx  slower' % (first.metrics.value / result.metrics.value)
          end

          $stdout.puts("%#{NAME_LENGTH}s: %11.1f %s #{slower}" % [result.job.name, result.metrics.value, @metrics_type.unit])
        end
        $stdout.puts
      end

      def compare_executables
        # TODO: implement
      end

      Result = ::BenchmarkDriver::Struct.new(:job, :metrics)
      private_constant :Result
    end
  end
end
