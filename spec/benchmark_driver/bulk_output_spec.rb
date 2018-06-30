require 'shellwords'

describe BenchmarkDriver::BulkOutput do
  describe '#bulk_output' do
    around do |example|
      env = ENV.to_h.dup
      ENV['RUBYOPT'] = ['-I', File.expand_path('../support', __dir__)].shelljoin
      example.run
      ENV.replace(env)
    end

    it 'allows to simplify output plugin implementation' do
      benchmark_driver fixture_yaml('blank_loop.yml'), '-o', 'test_output'
    end
  end
end
