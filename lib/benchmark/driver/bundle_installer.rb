require 'pathname'

# TODO: Support Windows... This depends on availability of which(1)
module Benchmark::Driver::BundleInstaller
  class << self
    # @param [Benchmark::Driver::Configuration::Executable] executable
    def bundle_install_for(executable)
      ruby_path = IO.popen(['which', executable.command.first], &:read).rstrip
      unless $?.success?
        abort "#{executable.command.first.dump} command was not found to execute `bundle install`"
      end

      bundler_path = Pathname.new(ruby_path).dirname.join('bundle')
      unless bundler_path.executable?
        abort "#{bundler_path.to_s.dump} was not a bundler executable, whose path was guessed from #{ruby_path.dump}"
      end
      bundle = bundler_path.to_s

      Bundler.with_clean_env do
        bundle_check(bundle, ruby: executable.name) || bundle_install(bundle)
      end
    end

    private

    # @param [String] bundle - full path to bundle(1)
    # @param [String] ruby - name of ruby
    # @return [TrueClass,FalseClass] - true if success
    def bundle_check(bundle, ruby:)
      output = IO.popen([bundle, 'check'], &:read)
      $?.success?.tap do |success|
        unless success
          $stderr.puts("For #{ruby}:")
          $stderr.print(output)
        end
      end
    end

    # @param [String] bundle - full path to bundle(1)
    def bundle_install(bundle)
      pid = Process.spawn(bundle, 'install', '-j', ENV.fetch('BUNDLE_JOBS', '4'))
      Process.wait(pid)
    end
  end
end
