require "spec_helper"

SingleCov.covered!

describe SplunkLogger do
  it "has a VERSION" do
    expect(SplunkLogger::VERSION).to match /^[\.\da-z]+$/
  end

  describe ".client" do
    it "creates an SplunkLogger::Client" do
      expect(SplunkLogger.client).to be_kind_of SplunkLogger::Client
    end
  end
end
