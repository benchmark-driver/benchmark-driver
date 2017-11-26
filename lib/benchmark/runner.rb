module Benchmark::Runner
  # TODO: make this dynamic to be pluggable
  def self.find(symbol)
    case symbol
    when :call
      Call
    when :exec
      Exec
    else
      raise NotImplementedError.new("Benchmark::Runner for #{symbol.inspect} is not found")
    end
  end
end

require 'benchmark/runner/call'
require 'benchmark/runner/exec'
