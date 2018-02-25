require 'bundler/gem_tasks'
require 'shellwords'

task :test do
  blank_loop = File.expand_path('./examples/yaml/blank_loop.yml', __dir__) # no warmup
  blank_hash = File.expand_path('./examples/yaml/blank_hash.yml', __dir__) # needs warmup
  {
    'ips' => 'compare',
    'time' => 'simple',
    'memory' => 'simple',
    'once' => 'markdown',
  }.each do |runner, output|
    Bundler.with_clean_env do
      sh ['time', 'bundle', 'exec', 'exe/benchmark-driver', blank_loop, '-r', runner, '-o', output].shelljoin
      sh ['time', 'bundle', 'exec', 'exe/benchmark-driver', blank_hash, '-r', runner, '-o', output, '--run-duration', '1'].shelljoin
    end
  end
end

task :test_record do
  blank_loop = File.expand_path('./examples/yaml/blank_loop.yml', __dir__) # no warmup
  sh ['time', 'bundle', 'exec', 'exe/benchmark-driver', blank_loop, '-r', 'ips', '-o', 'record'].shelljoin
  sh ['time', 'bundle', 'exec', 'exe/benchmark-driver', 'benchmark_driver.record.yml', '-o', 'compare'].shelljoin
  sh ['time', 'bundle', 'exec', 'exe/benchmark-driver', 'benchmark_driver.record.yml', '-o', 'record'].shelljoin
  sh ['time', 'bundle', 'exec', 'exe/benchmark-driver', 'benchmark_driver.record.yml', '-o', 'simple'].shelljoin
end

task :test_ruby do
  Dir.glob(File.expand_path('./examples/*.rb', __dir__)).sort.each do |file|
    Bundler.with_clean_env do
      sh ['time', 'bundle', 'exec', 'ruby', file].shelljoin
    end
    puts
  end
end

task :test_yaml do
  Dir.glob(File.expand_path('./examples/yaml/*.yml', __dir__)).sort.each do |file|
    Bundler.with_clean_env do
      sh ['time', 'bundle', 'exec', 'exe/benchmark-driver', file, '--run-duration', '1'].shelljoin
    end
    puts
  end
end

task default: [:test, :test_record, :test_ruby, :test_yaml]
