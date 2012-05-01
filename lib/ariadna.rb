module Ariadna
  class << self
    attr_accessor :connexion
  end
end

require "ariadna/version"
require "ariadna/account"
require "ariadna/analytics"
require "ariadna/connexion"
require "ariadna/delegator"
require "ariadna/profile"
require "ariadna/goal"
require "ariadna/result"
require "ariadna/error"
require "ariadna/error_code"
require "ariadna/web_property"