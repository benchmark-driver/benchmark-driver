describe 'Ruby interface' do
  def ruby(*args)
    assert_execute(RbConfig.ruby, *args)
  end

  Dir.glob(File.expand_path('./fixtures/ruby/*.rb', __dir__)).each do |script|
    it "runs #{File.basename(script)} with default options" do
      ruby script
    end
  end
end
