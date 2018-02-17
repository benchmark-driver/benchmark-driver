module BenchmarkDriver
  module Ruby
    class << JobRunner = Module.new
      # This method is dynamically called by `BenchmarkDriver::JobRunner.run`
      # @param [Array<BenchmarkDriver::Ruby::Job>] jobs
      # @param [BenchmarkDriver::Config] config
      def run(jobs, config:)
        # TODO: implement
      end
    end
  end
end
