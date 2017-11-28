# @param [Array<Benchmark::Driver::Configuration::Job>] jobs
# @param [Benchmark::Driver::Configuration::RunnerOptions] runner_options
# @param [Benchmark::Driver::Configuration::OutputOptions] output_options
class Benchmark::Driver::Configuration < Struct.new(:jobs, :runner_options, :output_options)
  # @param [String,nil] name
  # @param [String,Proc] sctipt
  # @param [String,nil] prelude
  # @param [Integer,nil] loop_count - If this is nil, loop count is automatically estimated by warmup.
  class Job < Struct.new(:name, :script, :prelude, :loop_count)
    def warmup_needed?
      loop_count.nil?
    end
  end

  # @param [String] name
  # @param [String] path
  Executable = Struct.new(:name, :path)

  DEFAULT_EXECUTABLES = [Executable.new(RUBY_VERSION, RbConfig.ruby)]

  # @param [Symbol] type - Type of runner
  # @param [Array<Benchmark::Driver::Configuration::Executable>] executables
  # @param [Integer,nil] repeat_count - Times to repeat benchmarks. When this is not nil, benchmark_driver will use the best result.
  class RunnerOptions < Struct.new(:type, :executables, :repeat_count)
    def initialize(*)
      super
      self.executables = DEFAULT_EXECUTABLES
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
end
