module Ariadna
  class WebProperty

    class << self; 
      attr_accessor :owner 
    end
    
    def self.all
      @properties ||= create_properties
    end

    def self.find(params)
      return [] if params.empty?
      all.each do |property|
        return property if get_a_match(params, property)
      end
      []
    end

    def initialize(item)
      item.each do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end

    def profiles
      Delegator.new(Profile, self)
    end

    private

    def self.create_properties
      properties = Ariadna.connexion.get_url(get_url)
      if (properties["totalResults"].to_i > 0)
        create_attributes(properties["items"])
        properties["items"].map do |property|
          WebProperty.new(property)
        end
      end
    end

    def self.create_attributes(items)
      items.first.each do |k,v|
        attr_reader k.to_sym
      end
    end

    def self.get_a_match(params, property)
      if params[:id]
        return true if property.id.downcase == params[:id].downcase
      end
      if params[:name]
        return true if property.name.downcase.include? params[:name].downcase 
      end
      return false
    end

    def self.get_url
      url = "https://www.googleapis.com/analytics/v3/management/accounts/#{@owner.id}/webproperties"
      if @web_property_id
        "#{url}/#{@web_property_id}"
      else
        url
      end
    end
  end
end