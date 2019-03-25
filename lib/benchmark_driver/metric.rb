require 'benchmark_driver/struct'

# All benchmark results should be expressed by this model.
module BenchmarkDriver
  # BenchmarkDriver returns benchmark results with the following nested Hash structure:
  # {
  #   #<BenchmarkDriver::Job> => {
  #     #<BenchmarkDriver::Context> => #<BenchmarkDriver::Result
  #       metrics: {
  #         #<BenchmarkDriver::Metric> => Float
  #       }
  #     >
  #   }
  # }

  # Holding identifier of measured workload
  Job = ::BenchmarkDriver::Struct.new(
    :name, # @param [String] - Name of the benchmark task
  )

  # Benchmark conditions that can be known before running benchmark
  Context = ::BenchmarkDriver::Struct.new(
    :name,        # @param [String] - Name of the context
    :executable,  # @param [BenchmarkDriver::Config::Executable] - Measured Ruby executable
    :gems,        # @param [Hash{ String => String,nil }] - Gem -> version pairs used for the benchmark
    :prelude,     # @param [String,nil] - Context specific setup script (optional)
    defaults: { prelude: '', gems: {} },
  )

  # Everything that can be known after running benchmark
  Result = ::BenchmarkDriver::Struct.new(
    :values,      # @param [Hash{ BenchmarkDriver::Metric => Float }] - Main benchmark results
    :all_values,  # @param [Hash{ BenchmarkDriver::Metric => Float }] - All benchmark results (optional)
    :duration,    # @param [Float,nil] - Time taken to run the benchmark job (optional)
    :loop_count,  # @param [Integer,nil] - Times to run the benchmark job (optional)
    :environment, # @param [Hash] - Any other key -> value pairs to express the benchmark context
    defaults: { environment: {} },
  )
  Result::ERROR = 0

  # A kind of thing to be measured
  Metric = ::BenchmarkDriver::Struct.new(
    :name,          # @param [String] - Metric name or description like "Max Resident Set Size"
    :unit,          # @param [String] - A unit like "MiB"
    :larger_better, # @param [TrueClass,FalseClass] - If true, larger value is preferred when measured multiple times.
    :worse_word,    # @param [String] - A label shown when the value is worse.
    defaults: { larger_better: true, worse_word: 'slower' },
  )

  #=[RubyBench mapping]=======================================|
  #
  # BenchmarkRun:
  #   result              -> { context.name => result.value } | { "default"=>"44.666666666666664", "default_jit"=>"59.333333333333336" }
  #   environment         -> result.environment               | "---\nRuby version: 'ruby 2.6.0dev (2018-05-14 trunk 63417) [x86_64-linux]\n\n'\nChecksum: '59662'\n"
  #   initiator           -> (not supported)                  | #<Commit sha1: "6f0de6ed9...", message: "error.c: check redefined ...", url: "https://github.com/tgxworld/ruby/commit/6f0de6ed98...", repo_id: 6>
  #
  #   BenchmarkType:
  #     category          -> job.name                         | "app_erb", "Optcarrot Lan_Master.nes"
  #     script_url        -> (not supported)                  | "https://raw.githubusercontent.com/mame/optcarrot/master/lib/optcarrot/nes.rb"
  #     repo              -> (not supported)                  | #<Repo name: "ruby", url: "https://github.com/tgxworld/ruby">
  #     repo.organization -> (not supported)                  | #<Organization name: "ruby", url: "https://github.com/tgxworld/">
  #
  #   BenchmarkResultType:
  #     name              -> metric.name                      | "Number of frames"
  #     unit              -> metric.unit                      | "fps"
  #
  #===========================================================|

  #----
  # legacy

  module Metrics
    Type = ::BenchmarkDriver::Struct.new(
      :unit,          # @param [String] - A label of unit for the value.
      :larger_better, # @param [TrueClass,FalseClass] - If true, larger value is preferred when measured multiple times.
      :worse_word,    # @param [String] - A label shown when the value is worse.
      defaults: { larger_better: true, worse_word: 'slower' },
    )
  end
end
