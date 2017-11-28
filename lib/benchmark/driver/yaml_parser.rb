module Benchmark::Driver::YamlParser
  DEFAULT_RUNNER = :exec # In YamlParser, we can't use :call.
  DEFAULT_OUTPUT = :ips

  class << self
    # @param [String] prelude
    # @param [Integer,nil] loop_count
    # @param [String,Array<String,Hash{ Symbol => String }>,Hash{ Symbol => String }] benchmark
    # @param [String,Symbol,Hash{ Symbol => Integer,TrueClass,FalseClass }] runner
    # @param [String,Symbol,Hash{ Symbol => Integer,TrueClass,FalseClass }] output
    # @return [Benchmark::Driver::Configuration]
    def parse(prelude: '', loop_count: nil, benchmark:, runner: {}, output: {})
      jobs = parse_benchmark(benchmark)
      jobs.each do |job|
        job.prelude = prelude
        job.loop_count ||= loop_count
      end

      config = Benchmark::Driver::Configuration.new(jobs)
      config.runner_options = parse_runner(runner)
      config.output_options = parse_output(output)
      config
    end

    private

    # @param [String,Symbol,Hash{ Symbol => Integer,TrueClass,FalseClass }] runner
    def parse_runner(runner)
      case runner
      when String, Symbol
        Benchmark::Driver::Configuration::RunnerOptions.new(runner.to_sym)
      when Hash
        parse_runner_options(runner)
      else
        raise ArgumentError.new("Expected String, Symbol or Hash in runner, but got: #{runner.inspect}")
      end
    end

    def parse_runner_options(type: DEFAULT_RUNNER, repeat_count: nil)
      Benchmark::Driver::Configuration::RunnerOptions.new.tap do |r|
        r.type = type.to_sym
        r.repeat_count = Integer(repeat_count) if repeat_count
      end
    end

    # @param [String,Symbol,Hash{ Symbol => Integer,TrueClass,FalseClass }] output
    def parse_output(output)
      case output
      when String, Symbol
        Benchmark::Driver::Configuration::OutputOptions.new(output.to_sym)
      when Hash
        parse_output_options(output)
      else
        raise ArgumentError.new("Expected String, Symbol or Hash in output, but got: #{output.inspect}")
      end
    end

    def parse_output_options(type: DEFAULT_OUTPUT, compare: false)
      Benchmark::Driver::Configuration::OutputOptions.new.tap do |r|
        r.type = type.to_sym
        r.compare = compare
      end
    end

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
