module BenchmarkDriver
  module Rbenv
    def self.ruby_path(version)
      path = `RBENV_VERSION='#{version}' rbenv which ruby`.rstrip
      unless $?.success?
        abort "Failed to execute 'rbenv which ruby'"
      end
      path
    end
  end
end
