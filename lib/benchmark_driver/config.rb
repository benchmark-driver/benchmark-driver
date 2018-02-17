require 'benchmark_driver/freezable_struct'

module BenchmarkDriver
  Config = FreezableStruct.new(
    :output,       # @param [String] output
    :execs,        # @param [Array<BenchmarkDriver::Config::Executable>]
    :repeat_count, # @param [Integer] repeat_count
  ) do
    def initialize(*)
      super
      self.execs ||= []
    end
  end

  Config::Executable = FreezableStruct.new(
    :name,    # @param [String]
    :command, # @param [Array<String>]
  )
end
