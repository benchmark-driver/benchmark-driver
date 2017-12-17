module Benchmark
  # RubyDriver entrypoint.
  def self.driver(*args, &block)
    dsl = Driver::RubyDslParser.new(*args)
    block.call(dsl)

    Driver.run(dsl.configuration)
  end

  module Driver
    class InvalidConfig < StandardError; end

    class << self
      # Main function which is used by both RubyDriver and YamlDriver.
      # @param [Benchmark::Driver::Configuration] config
      def run(config)
        validate_config(config)
        if config.runner_options.type.nil?
          config.runner_options.type = runner_type_for(config)
        end

        if config.runner_options.bundler
          config.runner_options.executables.each do |executable|
            Benchmark::Driver::BundleInstaller.bundle_install_for(executable)
            executable.command << '-rbundler/setup'
          end
        end

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
        if config.jobs.empty?
          raise InvalidConfig.new('No benchmark script is specified')
        end

        script_class = config.jobs.first.script.class
        unless config.jobs.all? { |j| j.script.is_a?(script_class) }
          raise InvalidConfig.new('Benchmark scripts include both String and Proc. Only either of them should be specified.')
        end

        # TODO: invalidate prelude for call runner
      end

      def runner_type_for(config)
        script_class = config.jobs.first.script.class
        if script_class == Proc
          :call
        elsif config.runner_options.executables_specified?
          :exec
        else
          :eval
        end
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
require 'benchmark/driver/bundle_installer'
require 'benchmark/driver/error'
require 'benchmark/driver/ruby_dsl_parser'
require 'benchmark/driver/version'
