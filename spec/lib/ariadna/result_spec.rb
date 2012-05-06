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
    it "save dimensions and metrics as attributes" do
      @results.first.country.should == "United States"
      @results.first.visits.should  == 94351
    end

    it "save general query information" do
      @results.first.itemsPerPage.should == 5
      @results.first.query["start-date"].should == "2010-04-01"
    end

    it "return data" do
      @results.size.should == 5
    end

    it "returns an array of results objects" do
      @results.first.class.should == Ariadna::Result
    end

    context "total headers" do
      it "creates a total result attribute and populates it" do
        @results.first.total_visits.should == "241543"
      end
    end
  end

  context "generates a url following google api rules" do

    before :each do
      @profile.results.select(
        :metrics    => [:visits, :bounces, :timeOnSite],
        :dimensions => [:country]
      )
      .where(
        :start_date => Date.today,
        :end_date   => Date.today,
        :browser    => "==Firefox"
      )
      .limit(100)
      .offset(40)
      .order([:visits, :bounces])
      .all
    end

    it "should include google api v3" do
      Ariadna::Result.url.include?("https://www.googleapis.com/analytics/v3/data/ga").should be
    end

    it "should include profile id" do
      Ariadna::Result.url.include?("ga:#{@profile.id}").should be
    end

    it "should include start and end date" do
      #Ariadna::Result.url.should == ""
      Ariadna::Result.url.include?("start-date=#{Date.today.strftime("%Y-%m-%d")}").should be
      Ariadna::Result.url.include?("end-date=#{Date.today.strftime("%Y-%m-%d")}").should be
    end

    it "should add metrics" do
      Ariadna::Result.url.include?("metrics=ga:visits,ga:bounces,ga:timeOnSite").should be
    end

    it "should add dimensions" do
      Ariadna::Result.url.include?("dimensions=ga:country").should be
    end

    it "should add max results" do
      Ariadna::Result.url.include?("max-results=100").should be
    end

    it "should add an offset" do
      Ariadna::Result.url.include?("start-index=40").should be
    end

    it "should add filters" do
      Ariadna::Result.url.include?("filters=ga:browser%3D%3DFirefox").should be
    end
  end

  context "Generate results with a profile id" do
    it "should include a profile id" do
      Ariadna::Result.profile(998877)
      .select(
        :metrics    => [:visits, :bounces, :timeOnSite],
        :dimensions => [:country]
      )
      .where(
        :start_date => Date.today,
        :end_date   => Date.today,
        :browser    => "==Firefox"
      )
      .limit(100)
      .offset(40)
      .order([:visits, :bounces])
      .all

      Ariadna::Result.url.include?("ga:998877").should be
    end
  end
end