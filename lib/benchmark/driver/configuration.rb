# @param [String,nil] prelude
# @param [Array<Benchmark::Driver::Configuration::Job>] jobs
class Benchmark::Driver::Configuration < Struct.new(:prelude, :jobs)
  # @param [String,nil] name
  # @param [String,Proc] sctipt
  Job = Struct.new(:name, :script)
end
