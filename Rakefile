require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.ruby_opts = %w[-w]
  t.rspec_opts = %w[--profile]
end

task default: :spec

# task :test_ruby do
#   Dir.glob(File.expand_path('./examples/*.rb', __dir__)).sort.each do |file|
#     Bundler.with_clean_env do
#       sh ['time', 'bundle', 'exec', 'ruby', file].shelljoin
#     end
#     puts
#   end
# end

# task :test_yaml do
#   Dir.glob(File.expand_path('./examples/yaml/*.yml', __dir__)).sort.each do |file|
#     Bundler.with_clean_env do
#       sh ['time', 'bundle', 'exec', 'exe/benchmark-driver', file, '--run-duration', '1'].shelljoin
#     end
#     puts
#   end
# end

# task default: [:test, :test_record, :test_ruby, :test_yaml]
