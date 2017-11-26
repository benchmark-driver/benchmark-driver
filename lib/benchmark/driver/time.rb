module Benchmark::Driver::Time
  if defined?(Process::CLOCK_MONOTONIC)
    def self.now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  else
    $stderr.puts "Process::CLOCK_MONOTONIC was unavailable. Using Time."
    def self.now
      ::Time.now
    end
  end
end
