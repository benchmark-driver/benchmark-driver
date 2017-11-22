module Benchmark::Output::ExecutionTime
  class << self
    # @param [Array<Executable>] execs
    # @param [Array<BenchmarkResult>] results
    def report(execs, results)
      puts "benchmark results:"
      puts "Execution time (sec)"
      puts "#{'%-16s' % 'name'} #{execs.map { |e| "%-8s" % e.name }.join(' ')}"

      results.each do |result|
        print '%-16s ' % result.name
        puts execs.map { |exec|
          "%-8s" % ("%.3f" % result.elapsed_time_of(exec))
        }.join(' ')
      end
      puts

      if execs.size > 1
        report_speedup(execs, results)
      end
    end

    private

    def report_speedup(execs, results)
      compared = execs.first
      rest = execs - [compared]

      puts "Speedup ratio: compare with the result of `#{compared.name}' (greater is better)"
      puts "#{'%-16s' % 'name'} #{rest.map { |e| "%-8s" % e.name }.join(' ')}"
      results.each do |result|
        print '%-16s ' % result.name
        puts rest.map { |exec|
          "%-8s" % ("%.3f" % (result.ips_of(exec) / result.ips_of(compared)))
        }.join(' ')
      end
      puts
    end
  end
end
