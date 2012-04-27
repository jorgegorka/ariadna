module Ariadna
  class WebProperty

    class << self; 
      attr_accessor :owner 
    end
    
    def self.all
      @properties ||= create_properties
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
      properties = Ariadna.connexion.get_url("https://www.googleapis.com/analytics/v3/management/accounts/#{@owner.id}/webproperties")
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
  end
end