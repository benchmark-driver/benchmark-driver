module BenchmarkDriver
  class RubyInterface
    def self.run(**args, &block)
      new(**args).tap { |x| block.call(x) }.run
    end

    # Build jobs and run. This is NOT interface for users.
    def run
      unless @executables.empty?
        @config.executables = @executables
      end

      jobs = @jobs.flat_map do |job|
        BenchmarkDriver::JobParser.parse({
          type: @config.runner_type,
          prelude: @prelude,
          loop_count: @loop_count,
        }.merge!(job))
      end
      BenchmarkDriver::Runner.run(jobs, config: @config)
    end

    #
    # Config APIs from here
    #

    # @param [String,NilClass] output
    # @param [String,NilClass] runner
    def initialize(output: nil, runner: nil, repeat_count: 1)
      @prelude = ''
      @loop_count = nil
      @jobs = []
      @config = BenchmarkDriver::Config.new
      @config.output_type = output.to_s if output
      @config.runner_type = runner.to_s if runner
      @config.repeat_count = Integer(repeat_count)
      @executables = []
    end

    # @param [String] script
    def prelude(script)
      @prelude << "#{script}\n"
    end

    # @param [Integer] count
    def loop_count(count)
      @loop_count = count
    end

    # @param [String] name - Name shown on result output.
    # @param [String,nil] script - Benchmarked script in String. If nil, name is considered as script too.
    def report(name, script = nil)
      if script.nil?
        script = name
      end
      @jobs << { benchmark: [{ name: name, script: script }] }
    end

    def output(type)
      @config.output_type = type
    end

    # Backward compatibility. This is actually default now.
    def compare!
      @config.output_type = 'compare'
    end

    def rbenv(*versions)
      versions.each do |version|
        @executables << BenchmarkDriver::Rbenv.parse_spec(version)
      end
    end

    def executable(name:, command:)
      raise ArgumentError, "`command' should be an Array" unless command.kind_of? Array
      @executables << BenchmarkDriver::Config::Executable.new(name: name, command: command)
    end

    def verbose(level = 1)
      @config.verbose = level
    end
  end
end
