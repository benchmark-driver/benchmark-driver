module Benchmark::Driver::YamlParser
  DEFAULT_RUNNER = :exec # In YamlParser, we can't use :call.
  DEFAULT_OUTPUT = :ips

  class << self
    # @param [String] prelude
    # @param [Integer,nil] loop_count
    # @param [String,Array<String,Hash{ Symbol => String }>,Hash{ Symbol => String }] benchmark
    # @return [Benchmark::Driver::Configuration]
    def parse(prelude: '', loop_count: nil, benchmark:)
      jobs = parse_benchmark(benchmark)
      jobs.each do |job|
        job.prelude = prelude
        job.loop_count ||= loop_count
      end

      Benchmark::Driver::Configuration.new(jobs)
    end

    private

    # Parse "benchmark" declarative. This may have multiple benchmarks.
    # @param [String,Array<String,Hash{ Symbol => String }>,Hash{ Symbol => String }] benchmark
    def parse_benchmark(benchmark)
      case benchmark
      when String
        [parse_each_benchmark(benchmark)]
      when Array
        benchmark.map { |b| parse_each_benchmark(b) }
      when Hash
        benchmark.map do |key, value|
          Benchmark::Driver::Configuration::Job.new(key.to_s, value)
        end
      else
        raise ArgumentError.new("benchmark must be String, Array or Hash, but got: #{benchmark.inspect}")
      end
    end

    # Parse one benchmark specified in "benchmark" declarative.
    # @param [String,Hash{ Symbol => String }>] job
    def parse_each_benchmark(benchmark)
      case benchmark
      when String
        Benchmark::Driver::Configuration::Job.new(benchmark, benchmark)
      when Hash
        parse_job(benchmark)
      else
        raise ArgumentError.new("Expected String or Hash in element of benchmark, but got: #{benchmark.inspect}")
      end
    end

    # @param [String,nil] name
    # @param [String] script
    # TODO: support benchmark-specific prelude
    def parse_job(name: nil, script:)
      name = script if name.nil?
      Benchmark::Driver::Configuration::Job.new(name, script)
    end
  end
end
