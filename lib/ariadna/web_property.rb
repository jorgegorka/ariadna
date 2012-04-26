module Ariadna
  class WebProperty

    class << self; 
      attr_accessor :owner 
    end

    attr_reader :id, :link_url, :name, :profiles_url, :parent_url, :profiles
    
    def self.all
      @properties ||= get_all_properties
    end

    def initialize(item)
      @id             = item["id"]
      @link_url       = item["selfLink"]
      @name           = item["name"]
      @account        = item["accountId"]
      @profiles_url   = item["childLink"]["href"]
      @parent_url     = item["parentLink"]["href"]
    end

    def profiles
      Delegator.new(Profile, self)
    end

    private

    def self.create_properties
      properties = Ariadna.connexion.get_url("https://www.googleapis.com/analytics/v3/management/accounts/#{@owner.id}/webproperties")
      if (properties["totalResults"].to_i > 0)
        properties["items"].map do |property|
          WebProperty.new(property)
        end
      end
    end

    def self.get_all_properties
      @properties = create_properties
    end
  end
end