require 'benchmark/output'
require 'benchmark/profiler'
require 'benchmark/runner'

module Benchmark::Driver::Engine
  class << self
    # @param [Benchmark::Driver::Configuration] config
    def run(config)
      validate_config(config)

      without_stdout_buffering do
        runner = Benchmark::Runner.find(config.runner_options.type).new(
          config.runner_options,
          output:   Benchmark::Output::Ips.new(config.output_options),
          profiler: Benchmark::Profiler::RealTime.new,
        )
        runner.run(config)
      end
    end

    private

    def validate_config(config)
      # TODO: make sure all scripts are the same class
    end

    # benchmark_driver ouputs logs ASAP. This enables sync flag for it.
    #
    # Currently benchmark_driver supports only output to stdout.
    # In future exetension, this may be included in Output plugins.
    def without_stdout_buffering
      sync, $stdout.sync = $stdout.sync, true
      yield
    ensure
      $stdout.sync = sync
    end
  end
end
