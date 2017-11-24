# @param [Array<Benchmark::Driver::Configuration::Job>] jobs
# @param [Symbol] runner
# @param [Hash{ Symbol => TrueClass,FalseClass }] output_options
class Benchmark::Driver::Configuration < Struct.new(:jobs, :runner, :output_options)
  # @param [String,nil] name
  # @param [String,Proc] sctipt
  # @param [String,nil] prelude
  Job = Struct.new(:name, :script, :prelude)

  def initialize(*)
    super
    self.output_options = {} if output_options.nil?
  end

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
