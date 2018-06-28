require 'open3'
require 'shellwords'
require 'tempfile'

describe 'benchmark-driver command' do
  def assert_execute(*command)
    stdout, stderr, status = Bundler.with_clean_env { Open3.capture3(*command) }
    command_to_show = command.map { |c| c.gsub(Dir.pwd, '.') }.shelljoin

    on_failure = -> {
      # Show output directly since RSpec truncates long output
      puts "\n\n#{'=' * 100}"
      puts "Failed to execute:\n#{command_to_show}"
      puts "\nstdout:\n```\n#{stdout}```\n\nstderr:\n```\n#{stderr}```\n\n\n"

      "Failed to execute: #{command_to_show}"
    }
    expect(status.success?).to eq(true), on_failure

    if ENV.key?('VERBOSE')
      puts "\n```\n$ #{command_to_show}\n#{stdout}```\n\n"
    end
    unless stderr.empty?
      $stderr.puts "stderr:\n```\n#{stderr}```"
    end
  end

  def benchmark_driver(*args)
    assert_execute(File.expand_path('../exe/benchmark-driver', __dir__), *args)
  end

  def fixture_yaml(name)
    File.expand_path("./fixtures/yaml/#{name}", __dir__)
  end

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

  Dir.glob(File.expand_path('./fixtures/yaml/*.yml', __dir__)).each do |yaml|
    it "runs #{File.basename(yaml)} with default options" do
      benchmark_driver yaml, '--run-duration', '0.2'
    end
  end
end
