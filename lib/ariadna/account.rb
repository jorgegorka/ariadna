module Ariadna
  class Account

    class << self; 
      attr_accessor :owner
    end

    URL = "https://www.googleapis.com/analytics/v3/management/accounts"
    
    def initialize(item)
      item.each do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end

    def self.all
      @accounts ||= create_accounts
    end

    def self.find(params)
      return [] if params.empty?
      all.each do |account|
        return account if get_a_match(params, account)
      end
      []
    end

    def properties
      Delegator.new(WebProperty, self)
    end

    private

    def self.create_accounts
      accounts = Ariadna.connexion.get_url(get_url)
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

    def self.get_a_match(params, account)
      if params[:id]
        return true if (account.id.to_i == params[:id].to_i) 
      end
      if params[:name]
        return true if account.name.downcase.include? params[:name].downcase 
      end
      return false
    end

    def self.get_url
      if @account_id
        "#{URL}/#{@account_id}"
      else
        URL
      end
    end
  end
end