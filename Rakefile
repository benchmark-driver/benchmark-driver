require 'bundler/gem_tasks'

desc 'Run benchmarks in benchmarks'
task :benchmarks do
  require 'bundler'
  require 'shellwords'

  Dir.glob(File.expand_path('./benchmarks/**/*.yml', __dir__)).sort.each do |path|
    Bundler.with_clean_env do
      sh [File.expand_path('./exe/benchmark-driver', __dir__), path].shelljoin
    end
  end
end

task default: :benchmarks
