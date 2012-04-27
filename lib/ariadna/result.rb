module Ariadna
  class Result

    class << self
      attr_accessor :owner
    end

    URL = "https://www.googleapis.com/analytics/v3/data/ga"

    def self.all
      get_results
    end

    # main filter conditions 
    def self.where(params)
      conditions.merge!(params)
      self
    end

    # sort conditions for the query
    def self.order(params)
      sort << params
      self
    end

    # lazy load query.  Only executed when actually needed
    def self.each(&block)
      get_results.each(&block)
    end

    private

    def self.conditions
      @conditions ||= {}
    end

    def self.sort
      @sort ||= []
    end

    def self.accessor_name(header)
      header["name"].sub('ga:', '')
    end

    # create attributes for each metric and dimension
    def self.create_attributes(results)
      summary_rows = Hash.new
      summary_rows.merge!(results)
      summary_rows.delete("columnHeaders")
      summary_rows.delete("rows")
      summary_rows.each do |row, value|
        attr_reader row.to_sym
      end
      summary_rows
    end

    # create attributes for each metric and dimension
    def self.create_metrics_and_dimensions(headers)
      headers.each do |header|
        attr_reader accessor_name(header).to_sym
      end
    end

    # map the json results collection into result objects
    # every metric and dimension is created as an attribute
    # I.E. You can get result.visits or result.bounces
    def self.get_results 
      url     = generate_url
      results = Ariadna.connexion.get_url(url)

      if (results["totalResults"].to_i > 0)
        #create an accessor for each summary attribute
        summary_rows = create_attributes(results)
        #create an accessor for each metric and dimension
        create_metrics_and_dimensions(results["columnHeaders"])
        results["rows"].map do |items|
          res = Result.new
          #assign values to summary fields
          summary_rows.each do |name, value|
            res.instance_variable_set("@#{name}", value)
          end
          #assign values to metrics and dimensions
          items.each do |item|
            res.instance_variable_set("@#{accessor_name(results["columnHeaders"][(items.index(item))])}", set_value_for_result(results["columnHeaders"][(items.index(item))], item))
          end
          res
        end
      end
    end

    def self.set_value_for_result(header, item)
      case header["dataType"]
      when "INTEGER"
        return item.to_i
      when "CURRENCY"
        return item.to_d
      when "FLOAT"
        return item.to_f
      when "TIME"
        Time.at(item.to_d).gmtime.strftime('%R:%S')
      else
        return item.to_s
      end
    end

    def self.generate_url
      params         = conditions.merge({"ids" => "ga:#{@owner.id}"})
      #params["sort"] = sort.join(",") if sort
      "#{URL}?" + params.map{ |k,v| "#{k}=#{v}"}.join("&")
    end
  end
end