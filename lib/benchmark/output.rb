module Benchmark::Output
  class << self
    # Benchmark::Output is pluggable.
    # Create `Benchmark::Output::FooBar` as benchmark-output-foo_bar.gem and specify `output: foo_bar`.
    #
    # @param [Symbol] name
    def find(name)
      class_name = Benchmark::Driver::Configuration.camelize(name.to_s)
      unless Benchmark::Output.const_defined?("#{class_name}::REQUIRED_FIELDS")
        require "benchmark/output/#{name}"
      end
      Benchmark::Output.const_get(class_name, false)
    end
  end
end

require 'benchmark/output/ips'
require 'benchmark/output/markdown'
require 'benchmark/output/memory'
require 'benchmark/output/time'
