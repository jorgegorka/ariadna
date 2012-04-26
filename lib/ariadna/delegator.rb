module Ariadna
  class Delegator < BasicObject
    
    def initialize(target, owner)
      @target       = target
      @target.owner = owner
    end

    protected
    
    def method_missing(name, *args, &block)
      target.send(name, *args, &block)
    end

    def target
      @target ||= []
    end

  end
end