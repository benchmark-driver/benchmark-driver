require 'shellwords'
require 'pathname'

module BenchmarkDriver
  module Rvm
    # Execute "which -a ruby" command to get a list of Ruby versions from $PATH.
    def self.system_ruby_path
      env_rubies = `which -a ruby`
      abort "Failed to execute 'which -a ruby'" unless $?.success?

      env_rubies.each_line do |line|
        if !line.match(ENV['rvm_path'])
          return line.rstrip
        end
      end
      abort "System ruby not found"
    end

    # @param [String] version
    def self.ruby_path(version)
      path = if version == 'system'
        system_ruby_path
      else
        rubies = Pathname.new("#{ENV['rvm_path']}/rubies")
        abort "Rubies path '#{rubies}' not found" unless rubies.exist?
        ruby_root = rubies.children.detect { |path| path.directory? && path.basename.to_s.match(version) }
        abort "Version '#{version}' not found" unless ruby_root
        "#{ruby_root}/bin/ruby"
      end

      unless File.exist?(path)
        abort "Binary '#{path}' not found"
      end
      path
    end

    # @param [String] full_spec - "2.5.0", "2.5.0 --jit", "JIT::2.5.0 --jit", etc.
    def self.parse_spec(full_spec)
      name, spec = full_spec.split('::', 2)
      spec ||= name # if `::` is not given, regard whole string as spec
      version, *args = spec.shellsplit
      BenchmarkDriver::Config::Executable.new(
        name: name,
        command: [BenchmarkDriver::Rvm.ruby_path(version), *args],
      )
    end
  end
end
