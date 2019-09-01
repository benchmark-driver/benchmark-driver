describe 'YAML interface' do
  def with_clean_env(&block)
    if Bundler.respond_to?(:with_unbundled_env)
      Bundler.with_unbundled_env do
        block.call
      end
    else
      Bundler.with_clean_env do
        block.call
      end
    end
  end

  Dir.glob(File.expand_path('./fixtures/yaml/*.yml', __dir__)).each do |yaml|
    it "runs #{File.basename(yaml)} with default options" do
      benchmark_driver yaml, '--run-duration', '0.2'
    end
  end

  it 'runs haml_render.yml with default options' do
    haml_checker = proc { |ver| with_clean_env { !system(RbConfig.ruby, '-e', "gem 'haml', '#{ver}'", err: File::NULL) } }
    if ENV['TRAVIS'] != 'true' && absent_ver = %w[4.0.7 5.0.4].find(&haml_checker)
      skip "haml.gem '#{absent_ver}' is not installed"
    end
    benchmark_driver fixture_extra('haml_render.yml'), '--run-duration', '0.2'
  end

  it 'exits normally with script error' do
    begin
      orig = $stderr
      $stderr = StringIO.new
      benchmark_driver fixture_extra('half_fail.yml'), '-v'
    ensure
      $stderr = orig
    end
  end

  it 'exits normally when benchmarks raise' do
    begin
      orig = $stderr
      $stderr = StringIO.new
      benchmark_driver fixture_extra('full_fail.yml'), '-v'
    ensure
      $stderr = orig
    end
  end

  it 'runs --output=all' do
    benchmark_driver File.expand_path('./fixtures/yaml/example_multi.yml', __dir__), '--output=all', '--run-duration=0.2'
  end
end
