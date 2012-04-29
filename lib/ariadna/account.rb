module Ariadna
  class Account

    class << self; 
      attr_reader :url 
      attr_accessor :owner
    end

    @url = "https://www.googleapis.com/analytics/v3/management/accounts"
    
    def initialize(item)
      item.each do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end

    def self.all
      @accounts ||= create_accounts
    end

    def properties
      Delegator.new(WebProperty, self)
    end

    private

    def self.create_accounts
      accounts = Ariadna.connexion.get_url(self.url)
      if (accounts["totalResults"].to_i > 0)
        create_attributes(accounts["items"])
        accounts["items"].map do |account|
          Account.new(account)
        end
      end
    end

    def self.create_attributes(items)
      items.first.each do |k,v|
        attr_reader k.to_sym
      end
    end
  end
end