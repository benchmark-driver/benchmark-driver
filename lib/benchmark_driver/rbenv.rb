module BenchmarkDriver
  module Rbenv
    # @param [String] version
    def self.ruby_path(version)
      path = `RBENV_VERSION='#{version}' rbenv which ruby`.rstrip
      unless $?.success?
        abort "Failed to execute 'rbenv which ruby'"
      end
      path
    end

    # @param [String] full_spec - "2.5.0", "2.5.0,--jit", "JIT::2.5.0,--jit", etc.
    def self.parse_spec(full_spec)
      name, spec = full_spec.split('::', 2)
      spec ||= name # if `::` is not given, regard whole string as spec
      version, *args = spec.split(',')
      BenchmarkDriver::Config::Executable.new(
        name: name,
        command: [BenchmarkDriver::Rbenv.ruby_path(version), *args],
      )
    end
  end
end
