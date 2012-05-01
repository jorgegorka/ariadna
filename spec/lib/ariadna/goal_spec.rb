require 'spec_helper'

describe "Profile" do
  before :each do
    conn       = Ariadna::Analytics.new("token")
    @account   = conn.accounts.all.first
    @property  = @account.properties.all.first
    @profile   = @property.profiles.all.first
  end

  context "A new goal" do
    before :each do
      new_goal = {
        "id"            => 666,
        "kind"          => "analytics#goals",
        "username"      => "username@gmail.com",
        "totalResults"  => 22,
        "startIndex"    => 1,
        "itemsPerPage"  => 100,
        "previousLink"  => "https://www.googleapis.com/analytics/v3/management/accounts/111/webproperties/909090/profiles/123456/goals",
        "nextLink"      => "https://www.googleapis.com/analytics/v3/management/accounts/111/webproperties/909090/profiles/123456/goals",
        "items"         => [
          {
            "id"                     => 667,
            "kind"                   => "analytics#goal",
            "selfLink"               => "http=>//www.url.com/goal",
            "accountId"              => 111,
            "webPropertyId"          => 909090,
            "internalWebPropertyId"  => 4321432,
            "profileId"              => 123456,
            "name"                   => "string",
            "value"                  => 2.5,
            "active"                 => true,
            "type"                   => "URL_DESTINATION",
            "created"                => Date.today,
            "updated"                => Date.today,
            "parentLink"             => {
              "type"  => "analytics#profile",
              "href"  => "https://www.googleapis.com/analytics/v3/management/accounts/111/webproperties/909090/profiles/123456"
            },
            "urlDestinationDetails"  => {
              "url"               => string,
              "caseSensitive"     => boolean,
              "matchType"         => string,
              "firstStepRequired" => boolean,
              "steps"             => [
                {
                  "number" => integer,
                  "name"   => string,
                  "url"    => string
                }
              ]
            },
            "visitTimeOnSiteDetails" => {
              "comparisonType"  => string,
              "comparisonValue" => long
            },
            "visitNumPagesDetails"   => {
              "comparisonType"  => string,
              "comparisonValue" => long
            },
            "eventDetails"           => {
              "useEventValue"   => boolean,
              "eventConditions" => [
                {
                  "type"            => string,
                  "matchType"       => string,
                  "expression"      => string,
                  "comparisonType"  => string,
                  "comparisonValue" => long
                }
              ]
            }
          }
        ]
      }
    end
  end
end