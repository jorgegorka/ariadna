module Ariadna
  class Profile

    class << self; 
      attr_accessor :owner 
    end
    
    def initialize(item)
      item.each do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end

    def self.all
      @profiles ||= create_profiles
    end

    def self.find(params)
      return [] if params.empty?
      all.each do |profile|
        return profile if get_a_match(params, profile)
      end
      []
    end

    def results
      Delegator.new(Result, self)
    end

    private

    def self.create_profiles
      profiles = Ariadna.connexion.get_url(get_url)
      if (profiles["totalResults"].to_i > 0)
        create_attributes(profiles["items"])
        profiles["items"].map do |item|
          Profile.new(item)
        end
      end
    end

    def self.create_attributes(items)
      items.first.each do |k,v|
        attr_reader k.to_sym
      end
    end

    def self.get_a_match(params, profile)
      if params[:id]
        return true if profile.id.to_i == params[:id].to_i
      end
      if params[:name]
        return true if profile.name.downcase.include? params[:name].downcase 
      end
      return false
    end

    def self.get_url
      url = @owner.childLink["href"]
      if @profile_id
        "#{url}/#{@profile_id}"
      else
        url
      end
    end
  end
end