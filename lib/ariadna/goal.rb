module Ariadna
  class Goal
    class << self; 
      attr_accessor :owner 
    end
    
    def initialize(goal)
      goal.each do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end

    def self.all
      @goals ||= create_goals
    end

    private

    def self.create_goals
      goals = Ariadna.connexion.get_url(@owner.childLink["href"])
      if (goals["totalResults"].to_i > 0)
        create_attributes(goals["items"])
        goals["items"].map do |goal|
          Goal.new(goal)
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