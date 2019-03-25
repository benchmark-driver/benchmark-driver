describe 'YAML interface' do
  Dir.glob(File.expand_path('./fixtures/yaml/*.yml', __dir__)).each do |yaml|
    it "runs #{File.basename(yaml)} with default options" do
      benchmark_driver yaml, '--run-duration', '0.2'
    end
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

  it 'runs --output=all' do
    benchmark_driver File.expand_path('./fixtures/yaml/example_multi.yml', __dir__), '--output=all', '--run-duration=0.2'
  end
end
