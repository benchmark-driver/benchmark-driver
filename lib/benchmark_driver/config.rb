require 'benchmark_driver/struct'
require 'rbconfig'
require 'shellwords'

module BenchmarkDriver
  # All CLI options
  Config = ::BenchmarkDriver::Struct.new(
    :runner_type,   # @param [String]
    :output_type,   # @param [String]
    :output_opts,   # @param [Hash{ Symbol => Object }]
    :paths,         # @param [Array<String>]
    :executables,   # @param [Array<BenchmarkDriver::Config::Executable>]
    :filters,       # @param [Array<Regexp>]
    :repeat_count,  # @param [Integer]
    :repeat_result, # @param [String]
    :alternate,     # @param [TrueClass,FalseClass]
    :run_duration,  # @param [Float]
    :timeout,       # @param [Float,nil]
    :verbose,       # @param [Integer]
    defaults: {
      runner_type: 'ips',
      output_type: 'compare',
      output_opts: {},
      filters: [],
      repeat_count: 1,
      repeat_result: 'best',
      alternate: false,
      run_duration: 3.0,
      verbose: 0,
    },
  )

  # Subset of Config passed to JobRunner
  Config::RunnerConfig = ::BenchmarkDriver::Struct.new(
    :repeat_count,  # @param [Integer]
    :repeat_result, # @param [String]
    :alternate,     # @param [TrueClass,FalseClass]
    :run_duration,  # @param [Float]
    :timeout,       # @param [Float,nil]
    :verbose,       # @param [Integer]
  )

  Config::Executable = ::BenchmarkDriver::Struct.new(
    :name,    # @param [String]
    :command, # @param [Array<String>]
  ) do
    def initialize(*)
      super
      @cache = {} # modifiable storage even after `#freeze`
    end

    # @return [String] - Return result of `ruby -v`. This is for convenience of output plugins.
    def description
      @cache[:description] ||= IO.popen([*command, '-v'], &:read).rstrip
    end

    # @return [String] - Return RUBY_VERSION
    def version
      @cache[:version] ||= IO.popen([*command, '-e', 'print RUBY_VERSION'], &:read)
    end
  end
  Config.defaults[:executables] = [
    BenchmarkDriver::Config::Executable.new(name: RUBY_VERSION, command: [RbConfig.ruby, *ENV.fetch('RUBYOPT', '').shellsplit]),
  ]
end
