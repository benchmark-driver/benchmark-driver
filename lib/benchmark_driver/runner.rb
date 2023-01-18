module BenchmarkDriver
  module Runner
    require 'benchmark_driver/runner/command_stdout'
    require 'benchmark_driver/runner/ips'
    require 'benchmark_driver/runner/block'
    require 'benchmark_driver/runner/memory'
    require 'benchmark_driver/runner/once'
    require 'benchmark_driver/runner/recorded'
    require 'benchmark_driver/runner/ruby_stdout'
    require 'benchmark_driver/runner/time'
  end

  class << Runner
    # Main function which is used by both CLI and `Benchmark.driver`.
    # @param [Array<BenchmarkDriver::*::Job>] jobs
    # @param [BenchmarkDriver::Config] config
    def run(jobs, config:)
      if config.verbose >= 1
        config.executables.each do |exec|
          $stdout.puts "#{exec.name}: #{IO.popen([*exec.command, '-v'], &:read)}"
        end
      end

      runner_config = Config::RunnerConfig.new
      runner_config.members.each do |member|
        runner_config[member] = config[member]
      end

      jobs.group_by{ |j| j.respond_to?(:contexts) && j.contexts }.each do |contexts, contexts_jobs|
        contexts_jobs.group_by(&:metrics).each do |metrics, metrics_jobs|
          metrics_jobs.group_by(&:class).each do |klass, klass_jobs|
            runner = runner_for(klass)
            if runner_config.alternate && runner != BenchmarkDriver::Runner::RubyStdout
              abort "--alternate is supported only for ruby_stdout runner for now"
            end

            contexts = build_contexts(contexts, executables: config.executables)
            output = Output.new(
              type: config.output_type,
              metrics: metrics,
              jobs: klass_jobs.map { |job| BenchmarkDriver::Job.new(name: job.name) },
              contexts: contexts,
              options: config.output_opts,
            )
            with_clean_env do
              runner.new(config: runner_config, output: output, contexts: contexts).run(klass_jobs)
            end
          end
        end
      end
    end

    private

    def build_contexts(contexts, executables:)
      # If contexts are not specified, just use executables as contexts.
      if !contexts.is_a?(Array) || contexts.empty?
        return executables.map { |exec|
          BenchmarkDriver::Context.new(name: exec.name, executable: exec)
        }
      end

      with_executables, without_executables = contexts.partition { |context| context.name && context.executable }
      with_executables + build_contexts_with_executables(without_executables, executables)
    end

    def build_contexts_with_executables(contexts, executables)
      # Create direct product of contexts
      contexts.product(executables).map do |context, executable|
        name = context.name
        if name.nil?
          # Use the first gem name and version by default
          name = context.gems.first.join(' ')

          # Append Ruby executable name if it's matrix
          if executables.size > 1
            name = "#{name} (#{executable.name})"
          end
        end

        BenchmarkDriver::Context.new(
          name: name,
          executable: executable,
          gems: context.gems,
          prelude: context.prelude,
        )
      end
    end

    # Dynamically find class (BenchmarkDriver::*::JobRunner) for plugin support
    # @param [Class] klass - BenchmarkDriver::*::Job
    # @return [Class]
    def runner_for(klass)
      unless match = klass.name.match(/\ABenchmarkDriver::Runner::(?<namespace>[^:]+)::Job\z/)
        raise "Unexpected job class: #{klass}"
      end
      BenchmarkDriver.const_get("Runner::#{match[:namespace]}", false)
    end

    def with_clean_env(&block)
      # chruby sets GEM_HOME and GEM_PATH in your shell. We have to unset it in the child
      # process to avoid installing gems to the version that is running benchmark-driver.
      env = nil
      ['GEM_HOME', 'GEM_PATH'].each do |var|
        if ENV.key?(var)
          env ||= ENV.to_h
          ENV.delete(var)
        end
      end

      unless defined?(Gem::Version)
        # default-gem Bundler can be loaded and broken with --disable-gems
        return block.call
      end

      require 'bundler'
      if Bundler.respond_to?(:with_unbundled_env)
        Bundler.with_unbundled_env do
          block.call
        end
      else
        Bundler.with_clean_env do
          block.call
        end
      end
    rescue LoadError
      block.call
    ensure
      if env
        ENV.replace(env)
      end
    end
  end
end
