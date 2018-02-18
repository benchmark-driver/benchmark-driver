require 'benchmark/driver'

Benchmark.driver do |x|
  large_a = "Hellooooooooooooooooooooooooooooooooooooooooooooooooooo"
  large_b = "Wooooooooooooooooooooooooooooooooooooooooooooooooooorld"

  small_a = "Hello"
  small_b = "World"

  x.report('large') { "#{large_a}, #{large_b}!" }
  x.report('small') { "#{small_a}, #{small_b}!" }
  x.compare!
end
