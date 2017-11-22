# @param [String,nil] prelude
# @param [Array<Benchmark::Driver::Configuration::Report>] reports
class Benchmark::Driver::Configuration < Struct.new(:prelude, :reports)
  # @param [String,nil] name
  # @param [String,Proc] sctipt
  Report = Struct.new(:name, :script)
end
