require 'spec_helper'

describe "Result" do
  before :each do
    conn       = Ariadna::Analytics.new("token")
    @account   = conn.accounts.all.first
    @property  = @account.properties.all.first
    @profile   = @property.profiles.all.first
    @results   = @profile.results.all
  end

  context "Results from a query" do

    it "should save dimensions and metrics as attributes" do
      @results.first.country.should == "United States"
      @results.first.visits.should  == 94351
    end

    it "should save general query information" do
      @results.first.itemsPerPage.should == 5
      @results.first.query["start-date"].should == "2010-04-01"
    end

    it "should return data" do
      @results.size.should == 5
    end

    it "returns an array of results objects" do
      @results.first.class.should == Ariadna::Result
    end
  end
end