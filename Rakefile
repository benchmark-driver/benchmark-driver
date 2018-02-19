require 'bundler/gem_tasks'
require 'shellwords'

task :yaml_examples do
  Dir.glob(File.expand_path('./examples/yaml/*.yml', __dir__)).sort.each do |file|
    Bundler.with_clean_env do
      sh ['time', 'bundle', 'exec', 'exe/benchmark-driver', file].shelljoin
    end
    puts
  end
end

task default: :yaml_examples
