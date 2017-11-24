module Benchmark::Driver::YamlDriver
  class << self
    # @param [String] prelude
    # @param [String,Array<String,Hash{ Symbol => String }>,Hash{ Symbol => String }] benchmark
    def run(prelude: '', benchmark:)
      jobs = parse_benchmark(benchmark)
      jobs.each do |job|
        job.prelude = prelude
      end

      config = Benchmark::Driver::Configuration.new(jobs)
      config.runner = :exec                     # TODO: support other runners
      config.output_options = { compare: true } # TODO: support other options
      Benchmark::Driver::Engine.run(config)
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
          Benchmark::Driver::Configuration::Job.new(key, value)
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
