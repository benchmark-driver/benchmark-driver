# @param [Array<Benchmark::Driver::Configuration::Job>] jobs
# @param [Benchmark::Driver::Configuration::RunnerOptions] runner_options
# @param [Benchmark::Driver::Configuration::OutputOptions] output_options
class Benchmark::Driver::Configuration < Struct.new(:jobs, :runner_options, :output_options)
  # @param [String,nil] name
  # @param [String,Proc] sctipt
  # @param [String,nil] prelude
  # @param [Integer,nil] loop_count - If this is nil, loop count is automatically estimated by warmup.
  Job = Struct.new(:name, :script, :prelude, :loop_count) do
    # @param [Integer,nil] guessed_count - Set by runner only when loop_count is nil. This is not configuration.
    attr_accessor :guessed_count

    def warmup_needed?
      # This needs to check original configuration
      self[:loop_count].nil?
    end

    def loop_count
      self[:loop_count] || guessed_count
    end
  end

  # @param [String] name
  # @param [Array<String>] command - ["ruby", "-w", ...]. First element should be path to ruby command
  Executable = Struct.new(:name, :command) do
    def self.parse(name_path)
      name, path = name_path.split('::', 2)
      path = File.expand_path(path)
      Benchmark::Driver::Configuration::Executable.new(name, path ? path.split(',') : [name])
    end

    def self.parse_rbenv(spec)
      version, *args = spec.split(',')
      path = `RBENV_VERSION='#{version}' rbenv which ruby`.rstrip
      abort "Failed to execute 'rbenv which ruby'" unless $?.success?
      Benchmark::Driver::Configuration::Executable.new(version, [path, *args])
    end
  end

  DEFAULT_EXECUTABLES = [Executable.new(RUBY_VERSION, [RbConfig.ruby])]

  # @param [Symbol] type - Type of runner
  # @param [Array<Benchmark::Driver::Configuration::Executable>] executables
  # @param [Integer,nil] repeat_count - Times to repeat benchmarks. When this is not nil, benchmark_driver will use the best result.
  RunnerOptions = Struct.new(:type, :executables, :repeat_count, :bundler) do
    def initialize(*)
      super
      self.executables ||= DEFAULT_EXECUTABLES
    end

    def executables_specified?
      executables != DEFAULT_EXECUTABLES
    end
  end

  # @param [Symbol] type - Type of output
  # @param [TrueClass,FalseClass] compare
  OutputOptions = Struct.new(:type, :compare)

  # @param [Object] config
  def self.symbolize_keys!(config)
    case config
    when Hash
      config.keys.each do |key|
        config[key.to_sym] = symbolize_keys!(config.delete(key))
      end
    when Array
      config.map! { |c| symbolize_keys!(c) }
    end
    config
  end

  # @param [String] str
  def self.camelize(str)
    return str if str !~ /_/ && str =~ /[A-Z]+.*/
    str.split('_').map { |e| e.capitalize }.join
  end
end
