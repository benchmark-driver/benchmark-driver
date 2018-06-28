require 'open3'
require 'shellwords'

describe 'benchmark-driver command' do
  def benchmark_driver(*args)
    command = [File.expand_path('../exe/benchmark-driver', __dir__), *args]
    stdout, stderr, status = Bundler.with_clean_env { Open3.capture3(*command) }
    command_info = "#{command.shelljoin.gsub(Dir.pwd, '.')}\nstdout:\n```\n#{stdout}```\n\nstderr:\n```\n#{stderr}```"

    expect(status.success?).to eq(true), "Failed to execute:\n#{command_info}"
    expect(stderr.empty?).to eq(true), "stderr was not empty:\n#{command_info}"

    if ENV.key?('VERBOSE')
      puts "\n#{stdout}\n"
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
end
