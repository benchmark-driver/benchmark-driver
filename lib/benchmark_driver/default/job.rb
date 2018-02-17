require 'benchmark_driver/freezable_struct'

module BenchmarkDriver
  module Default
    Job = FreezableStruct.new(
      :name,       # @param [String] name
      :before,     # @param [String] before
      :script,     # @param [String] benchmark
      :after,      # @param [String] after
      :loop_count, # @param [Integer] loop_count
    ) do
      def initialize(*)
        super
        if before.nil?
          self.before = ''
        end
        if after.nil?
          self.after = ''
        end
      end
    end
  end
end
