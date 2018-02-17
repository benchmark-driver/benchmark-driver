module BenchmarkDriver
  module Default
    class << JobRunner = Module.new
      # This method is dynamically called by `BenchmarkDriver::JobRunner.run`
      # @param [Array<BenchmarkDriver::Default::Job>] jobs
      # @param [BenchmarkDriver::Config] config
      def run(jobs, config:)
        # TODO: implement
        require "pry";binding.pry
      end
    end
  end
end
