module BenchmarkDriver
  class RubyInterface
    def self.run(**args, &block)
      new(**args).tap { |x| block.call(x) }.run
    end

    # Build jobs and run. This is NOT interface for users.
    def run
      jobs = @jobs.flat_map do |job|
        BenchmarkDriver::JobParser.parse({
          type: @config.runner_type,
          prelude: @prelude,
        }.merge!(job))
      end
      BenchmarkDriver::Runner.run(jobs, config: @config)
    end

    #
    # Config APIs from here
    #

    # @param [String,NilClass] output
    # @param [String,NilClass] runner
    def initialize(output: nil, runner: nil)
      @prelude = ''
      @jobs = []
      @config = BenchmarkDriver::Config.new
      @config.output_type = output.to_s if output
      @config.runner_type = runner.to_s if runner
    end

    # @param [String] script
    def prelude(script)
      @prelude << "#{script}\n"
    end

    # @param [String] name - Name shown on result output.
    # @param [String,nil] script - Benchmarked script in String. If nil, name is considered as script too.
    def report(name, script = nil)
      if script.nil?
        script = name
      end
      @jobs << { benchmark: [{ name: name, script: script }] }
    end

    # Backward compatibility. This is actually default now.
    def compare!
      @config.output_type = 'compare'
    end
  end
end
