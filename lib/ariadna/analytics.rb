module Ariadna
  class Analytics
    def initialize(token, proxy_options=nil, refresh_info=nil)
      Ariadna.connexion = Connexion.new(token, proxy_options, refresh_info)
    end

    def accounts
      Delegator.new(Account, self)
    end    
  end
end