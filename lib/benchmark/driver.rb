module Benchmark
  module Driver
    class << self
      # Main function which is used by both RubyDriver and YamlDriver.
      # @param [Benchmark::Driver::Configuration] config
      def run(config)
        validate_config(config)

        without_stdout_buffering do
          runner = Runner.find(config.runner_options.type).new(
            config.runner_options,
            output: Output.create(config),
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

  # RubyDriver entrypoint.
  def self.driver(*args, &block)
    ruby_driver = Driver::RubyDriver.new(*args)
    block.call(ruby_driver)

    Driver.run(ruby_driver.configuration)
  end
end

require 'benchmark/output'
require 'benchmark/runner'
require 'benchmark/driver/ruby_driver'
require 'benchmark/driver/version'
