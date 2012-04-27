module Ariadna
  class Profile

    class << self; 
      attr_accessor :owner 
    end

    attr_reader :id, :link, :name, :goals, :parent
    
    def initialize(item)
      item.each do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end

    def self.all
      @profiles ||= create_profiles
    end

    def results
      Delegator.new(Result, self)
    end

    private

    def self.create_profiles
      profiles = Ariadna.connexion.get_url(@owner.childLink["href"])
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
  end
end