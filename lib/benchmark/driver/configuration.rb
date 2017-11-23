# @param [String,nil] prelude
# @param [Array<Benchmark::Driver::Configuration::Job>] jobs
# @param [Hash{ Symbol => TrueClass,FalseClass }] output_options
class Benchmark::Driver::Configuration < Struct.new(:prelude, :jobs, :output_options)
  # @param [String,nil] name
  # @param [String,Proc] sctipt
  Job = Struct.new(:name, :script)
end
