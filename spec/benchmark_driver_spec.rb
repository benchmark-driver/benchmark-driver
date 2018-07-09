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

  # 'recorded' => 'record'
  it 'records a result and outputs it in multiple ways' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        benchmark_driver fixture_yaml('blank_loop.yml'), '-r', 'ips', '-o', 'record'
        benchmark_driver 'benchmark_driver.record.yml', '-o', 'compare'
        benchmark_driver 'benchmark_driver.record.yml', '-o', 'record' # bootstrap
        benchmark_driver 'benchmark_driver.record.yml', '-o', 'simple'
      end
    end
  end

  it 'compares multiple Ruby executables' do
    benchmark_driver fixture_yaml('blank_loop.yml'), '-r', 'ips', '-o', 'compare',
      '-e', "ruby1::#{RbConfig.ruby}", '-e', "ruby2::#{RbConfig.ruby}"
  end

  it 'returns best result with repeats' do
    benchmark_driver fixture_yaml('blank_hash.yml'), '-r', 'ips', '-o', 'compare', '--run-duration', '0.1',
      '--repeat-count', '2', '--repeat-result', 'best'
  end

  it 'returns worst result with repeats' do
    benchmark_driver fixture_yaml('blank_hash.yml'), '-r', 'ips', '-o', 'compare', '--run-duration', '0.1',
      '--repeat-count', '2', '--repeat-result', 'worst'
  end

  it 'returns average result with repeats' do
    benchmark_driver fixture_yaml('blank_hash.yml'), '-r', 'ips', '-o', 'compare', '--run-duration', '0.1',
      '--repeat-count', '2', '--repeat-result', 'average'
  end

  it 'runs a Ruby script as single-execution benchmark' do
    Tempfile.open(['benchmark_driver-spec', '.rb']) do |f|
      f.puts "# hello"
      f.puts "100000.times { 3 * 3 }"
      f.close
      benchmark_driver f.path, '-v'
    end
  end
end
