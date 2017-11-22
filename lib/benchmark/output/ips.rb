module Benchmark::Output::Ips
  class << self
    # @param [Array<Executable>] execs
    # @param [Array<BenchmarkResult>] results
    def report(execs, results)
      puts "Result -------------------------------------------"
      puts "#{' ' * 16} #{execs.map { |e| "%13s" % e.name }.join('  ')}"

      results.each do |result|
        print '%16s ' % result.name
        puts execs.map { |exec|
          "%13s" % ("%.1f i/s" % result.ips_of(exec))
        }.join('  ')
      end
      puts

      if execs.size > 1
        compare(execs, results)
      end
    end

    private

    def compare(execs, results)
      results.each do |result|
        puts "Comparison: #{result.name}"

        sorted = execs.sort_by { |e| -result.ips_of(e) }
        first = sorted.first

        sorted.each do |exec|
          if exec == first
            puts "%16s: %12s i/s" % [first.name, "%.1f" % result.ips_of(first)]
          else
            puts "%16s: %12s i/s - %.2fx slower" % [exec.name, "%.1f" % result.ips_of(exec), result.ips_of(first) / result.ips_of(exec)]
          end
        end
        puts
      end
    end
  end
end
