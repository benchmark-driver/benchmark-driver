module Benchmark
  module Driver
    class << self
      # Main function which is used by exe/benchmark-driver.
      # @param [Benchmark::Driver::Configuration] config
      def run(config)
        validate_config(config)

        runner_class = Runner.find(config.runner_options.type)
        output_class = Output.find(config.output_options.type)

        missing_fields = output_class::REQUIRED_FIELDS - runner_class::SUPPORTED_FIELDS
        unless missing_fields.empty?
          raise ArgumentError.new(
            "#{output_class.name} requires #{missing_fields.inspect} fields "\
            "which are not supported by #{runner_class.name}. Try using another runner."
          )
        end

        without_stdout_buffering do
          runner = runner_class.new(
            config.runner_options,
            output: output_class.new(
              jobs:        config.jobs,
              executables: config.runner_options.executables,
              options:     config.output_options,
            ),
          )
          runner.run(config)
        end
      rescue Benchmark::Driver::Error => e
        $stderr.puts "\n\nFailed to execute benchmark!\n\n#{e.class.name}:\n  #{e.message}"
        exit 1
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
end

require 'benchmark/output'
require 'benchmark/runner'
require 'benchmark/driver/error'
require 'benchmark/driver/version'
