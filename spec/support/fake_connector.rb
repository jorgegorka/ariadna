require 'yaml'

module Ariadna
  #connector that loads fixtures instead of actually calling Google Analytics API
  class FakeConnector
    def initialize(token, proxy_options, refresh_token_options)
      #build_schema
    end

    def get_url(url)
      if url.include? "data/ga"
        load_results
      elsif url.include? "goals"
        #goals
      elsif url.include? "profiles"
        load_data('profiles')
      elsif url.include? "webproperties"
        load_data('webProperties')
      elsif url.include? "accounts"
        load_data('accounts')
      elsif url.include? "error"
        load_errors
      end
    end

    private

    def load_data(analytics_kind)
      items = YAML.load_file("#{File.dirname(__FILE__)}/../../spec/fixtures/#{analytics_kind}.yml")
      hashed_items = items.map do |name, item|
        item
      end
      {
        "kind"          => "analytics##{analytics_kind}",
        "username"      => "string",
        "totalResults"  => hashed_items.size,
        "startIndex"    => 1,
        "itemsPerPage"  => 1000,
        "previousLink"  => "prev",
        "nextLink"      => "next",
        "items"         => hashed_items
      }
    end

    def load_results
      items = YAML.load_file("#{File.dirname(__FILE__)}/../../spec/fixtures/results.yml")
      items.first[1]
    end

    def load_errors
      items = YAML.load_file("#{File.dirname(__FILE__)}/../../spec/fixtures/errors.yml")
      items.first[1]
    end
  end
end
