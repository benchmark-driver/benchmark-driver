module Benchmark::Runner
  # Benchmark::Runner is pluggable.
  # Create `Benchmark::Runner::FooBar` as benchmark-runner-foo_bar.gem and specify `runner: foo_bar`.
  #
  # Currently this has no options other than Exec, but this will have Eval for sure.
  #
  # @param [Symbol] name
  def self.find(name)
    class_name = Benchmark::Driver::Configuration.camelize(name.to_s)
    Benchmark::Runner.const_get(class_name, false)
  end
end

require 'benchmark/runner/exec'
