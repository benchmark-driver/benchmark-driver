require 'benchmark/output'
require 'benchmark/profiler'
require 'benchmark/runner'

class Benchmark::Driver::Engine
  # @param [Benchmark::Driver::Configuration] config
  def run(config)
    validate_config(config)

    without_stdout_buffering do
      output   = Benchmark::Output::Ips.new
      runner   = Benchmark::Runner::Call.new(output)
      profiler = Benchmark::Profiler::RealTime.new

      runner.run(config, profiler: profiler)
    end
  end

  private

  def validate_config(config)
    # TODO: make sure all scripts are the same class
  end

  # benchmark_driver ouputs logs ASAP. This enables sync flag for it.
  #
  # Currently benchmark_driver supports only output to stdout.
  # In future exetension, this may be included in Output plugins.
  def without_stdout_buffering
    sync, $stdout.sync = $stdout.sync, true
    yield
  ensure
    $stdout.sync = sync
  end
end
