require 'benchmark/driver'

class Array
  alias_method :blank?, :empty?
end

Benchmark.driver(runner: :eval) do |x|
  x.prelude %{ array = [] }
  x.report 'Array#empty?', %{ array.empty? }
  x.report 'Array#blank?', %{ array.blank? }
  x.compare!
end
