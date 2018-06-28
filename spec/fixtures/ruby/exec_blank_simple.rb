require 'benchmark_driver'

Benchmark.driver(output: :simple) do |x|
  x.prelude <<-EOS
    class Array
      alias_method :blank?, :empty?
    end
    array = []
  EOS
  x.report %{ array.empty? }
  x.report %{ array.blank? }
  x.loop_count 1000
end
