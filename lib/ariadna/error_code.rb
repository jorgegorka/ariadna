module Ariadna
  class ErrorCode
    def initialize(item)
      item.each do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end

    def self.get_errors(errors)
      create_attributes(errors.first)
      errors.map do |item|
        ErrorCode.new(item)
      end
    end

    def self.create_attributes(item)
      item.each do |k,v|
        attr_reader k.to_sym
      end
    end
  end
end