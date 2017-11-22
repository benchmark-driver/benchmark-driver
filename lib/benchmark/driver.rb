module Benchmark
  module Driver
  end

  def self.drive(&block)
    dsl = Driver::DSL.new
    block.call(dsl)

    Driver::Engine.new.run(dsl.configuration)
  end
end

require 'benchmark/driver/dsl'
require 'benchmark/driver/engine'
require 'benchmark/driver/version'
