module Benchmark::Driver
  class Error < StandardError
  end

  class ExecutionTimeTooShort < Error
    def initialize(job, iterations)
      @job = job
      @iterations = iterations
    end

    def message
      "Execution time of job #{@job.name.dump} was too short in #{@iterations} executions;\n  "\
        'Please retry, try slower script or increase loop_count.'
    end
  end
end
