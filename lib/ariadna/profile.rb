module Ariadna
  class Profile

    class << self; 
      attr_accessor :owner 
    end

    attr_reader :id, :link, :name, :goals, :parent
    
    def initialize(item)
      @id                           = item["id"]
      @link                         = item["selfLink"]
      @name                         = item["name"]
      @account                      = item["accountId"]
      @currency                     = item["currency"]
      @timezone                     = item["timezone"]
      @defaultPage                  = item["defaultPage"]
      @excludeQueryParameters       = item["excludeQueryParameters"]
      @siteSearchQueryParameters    = item["siteSearchQueryParameters"]
      @siteSearchCategoryParameters = item["siteSearchCategoryParameters"]
      @goals                        = item["childLink"]["href"]
      @parent                       = item["parentLink"]["href"]
    end

    def self.all
      @profiles ||= get_all_profiles
    end

    def results
      Delegator.new(Result, self)
    end

    private

    def self.create_profiles
      profiles = Ariadna.connexion.get_url(@owner.profiles_url)
      if (profiles["totalResults"].to_i > 0)
        profiles["items"].map do |item|
          Profile.new(item)
        end
      end
    end

    def self.get_all_profiles
      @profiles = create_profiles
    end
  end
end