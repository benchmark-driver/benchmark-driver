require 'benchmark/driver'

class Array
  alias_method :blank?, :empty?
end

Benchmark.driver do |x|
  x.prelude %{ array = [] }
  x.report 'Array#empty?', %{ array.empty? }
  x.report 'Array#blank?', %{ array.blank? }
  x.loop_count 10000000
  x.compare!
end
