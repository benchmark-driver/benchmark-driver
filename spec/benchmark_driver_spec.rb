require 'open3'
require 'shellwords'
require 'tempfile'

describe 'benchmark-driver command' do
  def benchmark_driver(*args)
    command = [File.expand_path('../exe/benchmark-driver', __dir__), *args]
    stdout, stderr, status = Bundler.with_clean_env { Open3.capture3(*command) }

    expect(status.success?).to eq(true), -> {
      # Show output directly since RSpec truncates long output
      command_to_show = command.map { |c| c.gsub(Dir.pwd, '.') }.shelljoin
      puts "\n\n#{'=' * 100}"
      puts "Failed to execute:\n#{command_to_show}"
      puts "\nstdout:\n```\n#{stdout}```\n\nstderr:\n```\n#{stderr}```\n\n\n"

      "Failed to execute: #{command_to_show}"
    }

    if ENV.key?('VERBOSE')
      puts "\n#{stdout}\n"
    end
    unless stderr.empty?
      $stderr.puts "stderr:\n```\n#{stderr}```"
    end
  end

  def fixture(name)
    File.expand_path("./fixtures/#{name}", __dir__)
  end

  {
    'ips' => 'compare',
    'time' => 'simple',
    'memory' => 'simple',
    'once' => 'markdown',
  }.each do |runner, output|
    it "runs benchmark with fixed loop_count, #{runner.dump} runner and #{output.dump} output" do
      expect {
        benchmark_driver fixture('blank_loop.yml'), '-r', runner, '-o', output
      }.not_to raise_error
    end

    it "runs benchmark with run duration, #{runner.dump} runner and #{output.dump} output" do
      expect {
        benchmark_driver fixture('blank_hash.yml'), '-r', runner, '-o', output, '--run-duration', '0.1'
      }.not_to raise_error
    end
  end

  it 'records a result and outputs it in multiple ways' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        expect {
          benchmark_driver fixture('blank_loop.yml'), '-r', 'ips', '-o', 'record'
          benchmark_driver 'benchmark_driver.record.yml', '-o', 'compare'
          benchmark_driver 'benchmark_driver.record.yml', '-o', 'record'
          benchmark_driver 'benchmark_driver.record.yml', '-o', 'simple'
        }.not_to raise_error
      end
    end
  end
end
