describe 'YAML interface' do
  Dir.glob(File.expand_path('./fixtures/yaml/*.yml', __dir__)).each do |yaml|
    it "runs #{File.basename(yaml)} with default options" do
      benchmark_driver yaml, '--run-duration', '0.2'
    end
  end

  it 'exits normally with script error' do
    yaml = <<-YAML
prelude: |
  array = []
benchmark:
  empty: array.empty?
  blank: raise 'error'
loop_count: 1000000
    YAML

    Tempfile.open(['half_fail', '.yml']) do |f|
      f.puts yaml
      f.close
      begin
        orig = $stderr
        $stderr = StringIO.new
        benchmark_driver f.path, '-v'
      ensure
        $stderr = orig
      end
    end
  end
end
