require 'tempfile'

describe 'benchmark-driver command' do
  {
    'ips' => 'compare',
    'time' => 'simple',
    'memory' => 'simple',
    'once' => 'markdown',
  }.each do |runner, output|
    it "runs benchmark with fixed loop_count, #{runner.dump} runner and #{output.dump} output" do
      benchmark_driver fixture_yaml('blank_loop.yml'), '-r', runner, '-o', output
    end

    it "runs benchmark with run duration, #{runner.dump} runner and #{output.dump} output" do
      benchmark_driver fixture_yaml('blank_hash.yml'), '-r', runner, '-o', output, '--run-duration', '0.1'
    end
  end

  it 'records a result and outputs it in multiple ways' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        benchmark_driver fixture_yaml('blank_loop.yml'), '-r', 'ips', '-o', 'record'
        benchmark_driver 'benchmark_driver.record.yml', '-o', 'compare'
        benchmark_driver 'benchmark_driver.record.yml', '-o', 'record'
        benchmark_driver 'benchmark_driver.record.yml', '-o', 'simple'
      end
    end
  end
end
