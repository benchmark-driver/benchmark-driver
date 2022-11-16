require 'shellwords'

module BenchmarkDriver
  module Chruby
    # @param [String] version
    def self.ruby_path(version)
      prefix = (Dir.glob('/opt/rubies/*') + Dir.glob("#{ENV['HOME']}/.rubies/*")).find do |dir|
        File.basename(dir) == version
      end
      unless prefix
        abort "Failed to find '#{version}' in /opt/rubies or ~/.rubies"
      end
      "#{prefix}/bin/ruby"
    end

    # @param [String] full_spec - "2.5.0", "2.5.0 --jit", "JIT::2.5.0 --jit", etc.
    def self.parse_spec(full_spec)
      name, spec = full_spec.split('::', 2)
      spec ||= name # if `::` is not given, use the whole string as spec
      version, *args = spec.shellsplit
      BenchmarkDriver::Config::Executable.new(
        name: name,
        command: [BenchmarkDriver::Chruby.ruby_path(version), *args],
      )
    end
  end
end
