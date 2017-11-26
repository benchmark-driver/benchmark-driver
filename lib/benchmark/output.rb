module Benchmark::Output
  class << self
    # @param [Benchmark::Driver::Configuration] config
    def create(config)
      find(config.output_options.type).new(
        jobs: config.jobs,
        options: config.output_options,
      )
    end

    private

    # TODO: make this dynamic to be pluggable
    def find(symbol)
      case symbol
      when :ips
        Ips
      when :time
        ExecutionTime
      else
        raise NotImplementedError.new("Benchmark::Output for #{symbol.inspect} is not found")
      end
    end
  end
end

require 'benchmark/output/ips'
require 'benchmark/output/execution_time'
