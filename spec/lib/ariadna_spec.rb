require 'ariadna'

describe Ariadna do
  context "creating a new object" do
    it "returns an instance of AnalyticsApi" do
      ariadna =  Ariadna::AnalyticsApi.new
      ariadna.class.should == Ariadna::AnalyticsApi
    end
  end
end