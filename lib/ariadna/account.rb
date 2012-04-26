module Ariadna
  class Account

    class << self; 
      attr_reader :url 
    end

    attr_reader :id, :link, :name, :properties_url, :properties

    @url = "https://www.googleapis.com/analytics/v3/management/accounts"
    
    def initialize(item)
      @id             = item["id"]
      @link           = item["selfLink"]
      @name           = item["name"]
      @properties_url = item["childLink"]["href"]
    end

    def properties
      Delegator.new(WebProperty, self)
    end

  end
end