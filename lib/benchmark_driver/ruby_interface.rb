module BenchmarkDriver
  class RubyInterface
    @mode = :run
    @instances = []

    def self.load(path)
      @mode = :load
      Kernel.load path
      raise "need exactly 1 Benchmark.driver call (got #{@instances.size})" if @instances.size != 1
      @instances[0].build_config
    end

    def self.run(**args, &block)
      instance = new(**args)
      block.call(instance)
      case @mode
      when :run
        instance.run
      when :load
        @instances << instance
        nil
      else
        raise "Unknown mode: #{@mode}"
      end
    end

    def build_config
      config = {
        prelude: @prelude,
        benchmark: {}
      }

      config[:loop_count] = @loop_count if @loop_count

      @jobs.each do |job|
        name, script = job[:benchmark].first.values_at(:name, :script)
        config[:benchmark][name] = script
      end

      config
    end

    # Build jobs and run. This is NOT interface for users.
    def run
      config = BenchmarkDriver::Config.new
      config.output_type = @output.to_s if @output
      config.runner_type = @runner.to_s if @runner
      config.repeat_count = Integer(@repeat_count) if @repeat_count
      config.verbose = @verbose if @verbose

      unless @executables.empty?
        config.executables = @executables
      end

      jobs = @jobs.map do |job|
        BenchmarkDriver::JobParser.parse({
          type: config.runner_type,
          prelude: @prelude,
          loop_count: @loop_count,
        }.merge!(job))
      end
      BenchmarkDriver::Runner.run(jobs, config: config)
    end

    #
    # Config APIs from here
    #

    # @param [String,NilClass] output
    # @param [String,NilClass] runner
    def initialize(output: nil, runner: nil, repeat_count: nil)
      @prelude = ''
      @loop_count = nil
      @jobs = []
      @output = output
      @runner = runner
      @repeat_count = repeat_count
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
    def report(name, script = name)
      @jobs << { benchmark: [{ name: name, script: script }] }
    end

    def output(type)
      @output = type
    end

    # Backward compatibility. This is actually default now.
    def compare!
      @output = 'compare'
    end

    def rbenv(*versions)
      versions.each do |version|
        @executables << BenchmarkDriver::Rbenv.parse_spec(version)
      end
    end

    def rvm(*versions)
      versions.each do |version|
        @executables << BenchmarkDriver::Rvm.parse_spec(version)
      end
    end

    # ridk use command for RubyInstaller2 on Windows
    def ridkuse(*versions)
      versions.each do |version|
        @executables << BenchmarkDriver::RidkUse.parse_spec(version)
      end
    end

    def executable(name:, command:)
      raise ArgumentError, "`command' should be an Array" unless command.kind_of? Array
      @executables << BenchmarkDriver::Config::Executable.new(name: name, command: command)
    end

    def verbose(level = 1)
      @verbose = level
    end
  end
end
