require 'spec_helper'

describe "Result" do
  before :each do
    conn       = Ariadna::Analytics.new("token")
    @account   = conn.accounts.all.first
    @property  = @account.properties.all.first
    @profile   = @property.profiles.all.first
    @results = @profile.results.all
  end

  context "Results from a query" do

    it "should return data" do
      @results.size.should == 5
    end

    it "returns an array of results objects" do
      @results.first.class.should == Ariadna::Result
    end
  end
end