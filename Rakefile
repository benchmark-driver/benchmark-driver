require 'bundler/gem_tasks'
require 'shellwords'

task :ruby_examples do
  Dir.glob(File.expand_path('./examples/*.rb', __dir__)).sort.each do |file|
    Bundler.with_clean_env do
      sh ['bundle', 'exec', 'ruby', file].shelljoin
    end
  end
end

task :yaml_examples do
  Dir.glob(File.expand_path('./examples/yaml/*.yml', __dir__)).sort.each do |file|
    Bundler.with_clean_env do
      sh ['bundle', 'exec', 'exe/benchmark-driver', file].shelljoin
    end
  end
end

task default: [:ruby_examples, :yaml_examples]
