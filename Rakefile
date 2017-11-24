require 'bundler/gem_tasks'
require 'shellwords'

task :run_examples do
  Dir.glob(File.expand_path('./examples/*.rb', __dir__)).sort.each do |file|
    Bundler.with_clean_env do
      sh ['bundle', 'exec', 'ruby', file].shelljoin
    end
  end
end

task default: :run_examples
