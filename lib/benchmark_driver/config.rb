require 'benchmark_driver/keyword_init_struct'

module BenchmarkDriver
  Config = KeywordInitStruct.new(
    :output,       # @param [String] output
    :execs,        # @param [Array<BenchmarkDriver::Config::Executable>]
    :repeat_count, # @param [Integer] repeat_count
    :filters,      # @param [Array<String>] filters
    :bundler,      # @param [TrueClass,FalseClass] bundler
    :dir,          # @param [TrueClass,FalseClass] dir
  ) do
    def initialize
      super
      self.execs ||= []
      self.filters ||= []
    end
  end

  Config::Executable = KeywordInitStruct.new(
    :name,    # @param [String]
    :command, # @param [Array<String>]
  )
end
