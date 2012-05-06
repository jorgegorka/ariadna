# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# Require this file using `require "spec_helper.rb"` to ensure that it is only
# loaded once.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
require 'ariadna'

module Ariadna
  # The test of the api is made through yml fixtures and a fake connector that loads it
  # It is easier to test things than adding JSon stuff all over the place

  class Analytics
    def initialize(token, proxy_options=nil, refresh_info=nil)
      Ariadna.connexion = FakeConnector.new(token, proxy_options, refresh_info)
    end
  end
end

Dir["#{File.dirname(__FILE__)}/../spec/support/*.rb"].sort.each { |ext| require ext }

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
end
