require 'spec_helper'

describe "WebProperty" do
  before :each do
    conn        = Ariadna::Analytics.new("token")
    @account    = conn.accounts.all.first
    @properties = @account.properties.all
  end

  context "A new web_property" do
    before :each do
      new_property = {
        "id"                    => 888888,
        "kind"                  => "analytics#webProperty",
        "selfLink"              => "selfLink",
        "accountId"             => @account.id,
        "internalWebPropertyId" => 4321432,
        "name"                  => "web_property_name",
        "websiteUrl"            => "http://www.url.com",
        "created"               => Date.today,
        "updated"               => Date.today,
        "parentLink"            => {
          "type" => "analytics#account",
          "href" => "https://www.googleapis.com/analytics/v3/management/accounts/#{@account_id}"
        },
        "childLink"             => {
          "type" => "analytics#profiles",
          "href" => "https://www.googleapis.com/analytics/v3/management/accounts/#{@account_id}/webproperties/888888/profiles"
        }
      }

      @property = Ariadna::WebProperty.new(new_property)
    end

    it "should map each value into attributes" do
      @property.kind.should              == "analytics#webProperty"
      @property.accountId.should         == @account.id
      @property.selfLink.should          == "selfLink"
      @property.childLink["href"].should == "https://www.googleapis.com/analytics/v3/management/accounts/#{@account_id}/webproperties/888888/profiles"
    end
  end

  context :profiles do
    before :each do
      @profiles = @properties.first.profiles.all
    end

    it "gets a list of profiles" do
      @profiles.size.should == 2
    end

    it "returns an array of profiles objects" do
      @profiles.first.class == Ariadna::Profile
    end
  end
end