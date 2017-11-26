# @param [Array<Benchmark::Driver::Configuration::Job>] jobs
# @param [Benchmark::Driver::Configuration::RunnerOptions] runner_options
# @param [Benchmark::Driver::Configuration::OutputOptions] output_options
class Benchmark::Driver::Configuration < Struct.new(:jobs, :runner_options, :output_options)
  # @param [String,nil] name
  # @param [String,Proc] sctipt
  # @param [String,nil] prelude
  Job = Struct.new(:name, :script, :prelude)

  # @param [Symbol] type - Type of runner
  # @param [Integer,nil] loop_count - If this is nil, loop count is automatically estimated by warmup.
  RunnerOptions = Struct.new(:type, :loop_count)

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
