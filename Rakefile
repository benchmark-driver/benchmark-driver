require 'bundler/gem_tasks'

desc 'Run benchmarks in ruby_benchmark_set'
task :ruby_benchmark_set do
  require 'bundler'
  require 'shellwords'

  Dir.glob(File.expand_path('./ruby_benchmark_set/**/*.yml', __dir__)).each do |path|
    Bundler.with_clean_env do
      sh [File.expand_path('./exe/benchmark_driver', __dir__), path].shelljoin
    end
  end
end

task default: :ruby_benchmark_set
