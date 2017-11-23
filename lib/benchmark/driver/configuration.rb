# @param [Array<Benchmark::Driver::Configuration::Job>] jobs
# @param [Hash{ Symbol => TrueClass,FalseClass }] output_options
class Benchmark::Driver::Configuration < Struct.new(:jobs, :runner, :output_options)
  # @param [String,nil] name
  # @param [String,Proc] sctipt
  # @param [String,nil] prelude
  Job = Struct.new(:name, :script, :prelude)
end
