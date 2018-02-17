require 'benchmark_driver/ruby/job'

module BenchmarkDriver
  module Ruby
    class << JobParser = Module.new
      # This method is dynamically called by `BenchmarkDriver::JobParser.parse`
      # @param [String] before
      # @param [String,Array<String,Hash{ Symbol => String }>,Hash{ Symbol => String }] benchmark
      # @param [String] after
      # @param [Integer] loop_count
      # @return [Array<BenchmarkDriver::Ruby::Job>]
      def parse(before: nil, benchmark:, after: nil, loop_count: nil)
        parse_benchmark(benchmark).each do |job|
          job.before.prepend("#{before}\n") if before
          job.after.prepend("#{after}\n") if after
          job.loop_count ||= loop_count
        end.each(&:deep_freeze)
      end

      private

      # @param [String,Array<String,Hash{ Symbol => String }>,Hash{ Symbol => String }] benchmark
      def parse_benchmark(benchmark)
        case benchmark
        when String
          [parse_job(benchmark)]
        when Array
          benchmark.map { |b| parse_each_benchmark(b) }
        when Hash
          benchmark.map do |key, value|
            Job.new(name: key.to_s, script: value)
          end
        else
          raise ArgumentError.new("benchmark must be String, Array or Hash, but got: #{benchmark.inspect}")
        end
      end

      # @param [String,Hash{ Symbol => String }>] bench
      def parse_job(benchmark)
        case benchmark
        when String
          Job.new(name: benchmark, script: benchmark)
        when Hash
          parse_job_hash(benchmark)
        else
          raise ArgumentError.new("Expected String or Hash in element of benchmark, but got: #{benchmark.inspect}")
        end
      end

      def parse_job_hash(name: nil, before: '', script:, after: '', loop_count: nil)
        name ||= script
        Job.new(name: name, before: before, script: script, after: after, loop_count: loop_count)
      end
    end
  end
end
