require 'benchmark/driver'

Benchmark.driver(runner: :exec) do |x|
  x.prelude <<-EOS
    class Array
      alias_method :blank?, :empty?
    end
    array = []
  EOS
  x.report 'Array#empty?', %{ array.empty? }
  x.report 'Array#blank?', %{ array.blank? }
  x.compare!
end
