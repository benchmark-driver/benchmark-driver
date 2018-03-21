require 'benchmark_driver'

Benchmark.driver do |x|
  x.prelude <<-EOS
    class Array
      alias_method :blank?, :empty?
    end
    array = []
  EOS
  x.report 'Array#empty?', %{ array.empty? }
  x.report 'Array#blank?', %{ array.blank? }
  x.output 'markdown'
end
