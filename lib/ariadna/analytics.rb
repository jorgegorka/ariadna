module Ariadna
  class Analytics
    def initialize(token, proxy_options=nil, refresh_info=nil)
      Ariadna.connexion = Connexion.new(token, proxy_options, refresh_info)
    end

    def get_accounts  
      get_all_accounts    
      create_accounts(@accounts["items"]) if (@accounts["totalResults"].to_i > 0)
    end

    private

    def create_accounts(items)
      items.map do |item|
        Account.new(item)
      end
    end

    def get_all_accounts
      @accounts ||= Ariadna.connexion.get_url(Account.url)
    end
  end
end