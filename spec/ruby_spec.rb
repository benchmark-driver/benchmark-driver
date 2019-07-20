describe 'Ruby interface' do
  def ruby(*args)
    assert_execute(RbConfig.ruby, *args)
  end

  Dir.glob(File.expand_path('./fixtures/ruby/*.rb', __dir__)).each do |script|
    it "runs #{File.basename(script)} with default options" do
      ruby script
    end
  end

  # for `make run` with test.rb requiring ruby/ruby/benchmark/lib/load.rb
  it 'supports --disable-gems' do
    lib_dir = File.expand_path('../lib', __dir__)
    Bundler.with_unbundled_env do
      Tempfile.open(['benchmark_driver-test', '.rb']) do |f|
        f.puts <<~EOS
          $:.unshift(#{lib_dir.dump})
          require 'benchmark_driver'

          Benchmark.driver do |x|
            x.report %q{
              h = {a: 1, b: 2, c: 3, d: 4}
            }
            x.loop_count 6000
          end
        EOS
        f.close

        ruby '--disable-gems', f.path
      end
    end
  end
end
