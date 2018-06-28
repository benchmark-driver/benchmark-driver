describe 'YAML interface' do
  Dir.glob(File.expand_path('./fixtures/yaml/*.yml', __dir__)).each do |yaml|
    it "runs #{File.basename(yaml)} with default options" do
      benchmark_driver yaml, '--run-duration', '0.2'
    end
  end
end
