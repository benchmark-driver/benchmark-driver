require 'benchmark/driver'

class Array
  alias_method :blank?, :empty?
end

Benchmark.driver(runner: :call) do |x|
  array = []

  x.report('array.empty?') { array.empty? }
  x.report('array.blank?') { array.blank? }
  x.compare!
end
