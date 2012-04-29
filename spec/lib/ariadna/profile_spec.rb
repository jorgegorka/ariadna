require 'spec_helper'

describe "Profile" do
  before :each do
    conn       = Ariadna::Analytics.new("token")
    @account   = conn.accounts.all.first
    @property  = @account.properties.all.first
    @profiles  = @property.profiles.all
  end

  context "A new web_property" do
    before :each do
      new_profile = {
        "id"                           => 888888,
        "kind"                         => "analytics#profile",
        "selfLink"                     => "selfLink",
        "accountId"                    => @account.id,
        "webPropertyId"                => 8383,
        "internalWebPropertyId"        => 4321432,
        "name"                         => "web_profile_name",
        "currency"                     => "USD",
        "timezone"                     => "CET",
        "defaultPage"                  => "index.html",
        "excludeQueryParameters"       => "s",
        "siteSearchQueryParameters"    => "",
        "siteSearchCategoryParameters" => "",
        "created"                      => Date.today,
        "updated"                      => Date.today,
        "parentLink"                   => {
          "type" => "analytics#webProperty",
          "href" => "parentLink"
        },
        "childLink"             => {
          "type" => "analytics#goals",
          "href" => "childLink"
        }
      }

      @profile = Ariadna::Profile.new(new_profile)
    end

    it "should map each value into attributes" do
      @profile.timezone.should                == "CET"
      @profile.excludeQueryParameters.should  == "s"
      @profile.defaultPage.should             == "index.html"
      @profile.childLink["href"].should       == "childLink"
    end
  end

  context :properties do
    it "returns a list of result objects" do
      @profiles.first.class == Ariadna::Result
    end
  end

  context :results do
    before :each do
      @profile = @profiles.first
    end

    it "gets a list of profiles" do
      @profiles.size.should == 2
    end

    it "returns a list of profiles objects" do
      @profile.class.should == Ariadna::Profile
    end
  end

  context "can find a profile by id or name" do
    it "should return an empty array if can not find anything" do
      profile = @property.profiles.find({})
      profile.size.should == 0
    end

    it "should return the requested account filtered by name" do
      profile = @property.profiles.find(:name => "profile")
      profile.id.should == 123456
    end

    it "should return the requested account filtered by id" do
      profile = @property.profiles.find(:id => 123456)
      profile.name.should == 'profile_name'
    end
  end
end