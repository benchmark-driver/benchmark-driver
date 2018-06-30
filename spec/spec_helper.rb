require 'open3'
require 'shellwords'
require 'benchmark_driver'

module BenchmarkDriverSpecHelper
  def assert_execute(*command)
    stdout, stderr, status = Open3.capture3(*command)
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
end

RSpec.configure do |config|
  config.include BenchmarkDriverSpecHelper

  if ENV.key?('RSPEC_RETRIES')
    require 'rspec/retry'

    # show retry status in spec process
    config.verbose_retry = true
    # show exception that triggers a retry if verbose_retry is set to true
    config.display_try_failure_messages = true

    config.around :each do |example|
      example.run_with_retry retry: Integer(ENV['RSPEC_RETRIES'])
    end
  end
end
