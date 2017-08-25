require "spec_helper"

RSpec.describe BenchmarkDriver do
  it "has a version number" do
    expect(BenchmarkDriver::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end
