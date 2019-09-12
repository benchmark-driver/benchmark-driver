require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.ruby_opts = %w[-w]
end
ENV['RSPEC_RETRIES'] ||= '3'

task default: :spec
