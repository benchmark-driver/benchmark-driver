module Benchmark::Output
  class << self
    # @param [Benchmark::Driver::Configuration] config
    def create(config)
      find(config.output_options.type).new(
        jobs:        config.jobs,
        executables: config.runner_options.executables,
        options:     config.output_options,
      )
    end

    private

    # Benchmark::Output is pluggable.
    # Create `Benchmark::Output::FooBar` as benchmark-output-foo_bar.gem and specify `output: foo_bar`.
    #
    # @param [Symbol] name
    def find(name)
      class_name = Benchmark::Driver::Configuration.camelize(name.to_s)
      Benchmark::Output.const_get(class_name, false)
    end
  end
end

require 'benchmark/output/ips'
require 'benchmark/output/time'
