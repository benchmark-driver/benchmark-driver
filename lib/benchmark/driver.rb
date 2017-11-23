module Benchmark
  module Driver
  end

  def self.driver(*args, &block)
    dsl = Driver::DSL.new(*args)
    block.call(dsl)

    Driver::Engine.run(dsl.configuration)
  end
end

require 'benchmark/driver/dsl'
require 'benchmark/driver/engine'
require 'benchmark/driver/version'
