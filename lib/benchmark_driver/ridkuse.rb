require 'open3'
require 'shellwords'

module BenchmarkDriver
  module RidkUse
    # Execute "ridk use list" command to get a list of Ruby versions.
    # 
    # * "ridk use list" is a sub-command of ridk. It returns a list of installed ruby ​​versions.
    # * "ridk" is a helper command tool of RubyInstaller2 for Windows, that to manage the runtime environment of RubyInstaller-2.4 and up.
    #
    # refer to:
    # {The ridk tool · oneclick/rubyinstaller2 Wiki}[https://github.com/oneclick/rubyinstaller2/wiki/The-ridk-tool]
    #
    def self.ridk_use_list
      ruby_list = []
      regex = /(\d+)\s-\s([^\s]+)\s\truby\s([^\s]+)\s/
      cmd = "ridk use list"
      stdout, status = Open3.capture2e(cmd)

      stdout.each_line do |line|
        if matched = regex.match(line)
          idx, rubypath, rubyver = matched[1..3]
          ruby_list << rubyver << [idx, "#{rubypath}/bin/ruby.exe"]
        else
          abort "Failed to execute 'ridk use list'"
        end
      end
      Hash[*ruby_list]
    end
    
    # @param [String] version
    def self.ruby_path(version)
      ruby_list = BenchmarkDriver::RidkUse.ridk_use_list
      regex = Regexp.new(version)
      matched = ruby_list.keys.find {|k| k =~ regex}

      if ruby_list.has_key?(version)
        ruby_list[version][1]
      elsif matched
        ruby_list[matched][1]
      else
        abort "version #{version} not found"
      end
    end

    # @param [String] full_spec - "2.6.3", "2.6.3p62", "2.6.3,--jit", etc.
    def self.parse_spec(full_spec)
      name, spec = full_spec.split('::', 2)
      spec ||= name # if `::` is not given, regard whole string as spec
      version, *args = spec.shellsplit
      BenchmarkDriver::Config::Executable.new(
        name: name,
        command: [BenchmarkDriver::RidkUse.ruby_path(version), *args],
      )
    end
  end
end
