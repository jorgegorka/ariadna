module Ariadna
  class Result

    class << self
      attr_accessor :owner
      attr_accessor :url
    end

    URL = "https://www.googleapis.com/analytics/v3/data/ga"

    #gel all results
    def self.all
      get_results
    end

    # metrics and dimensions

    def self.select(params)
      get_metrics_and_dimensions(params)
      self
    end

    # main filter conditions 
    def self.where(params)
      extract_dates(params)
      get_filters(params) unless params.empty?
      self
    end

    # sort conditions for the query
    def self.order(params)
      conditions.merge!({"sort" => api_compatible_names(params)})
      self
    end

    # number of results returned
    def self.limit(results)
      if ((results.to_i > 0) and (results.to_i < 1001))
        conditions.merge!({"max-results" => results.to_i})
      end
      self
    end

    # number of row from which to start collecting results (used for pagination)
    def self.offset(offset)
      if (offset.to_i > 0) 
        conditions.merge!({"start-index" => offset.to_i})
      end
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
      self.url = generate_url
      results  = Ariadna.connexion.get_url(self.url)

      return results unless results.is_a? Hash

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
      params = conditions.merge({"ids" => "ga:#{@owner.id}"})
      "#{URL}?" + params.map{ |k,v| "#{k}=#{v}"}.join("&")
    end

    def self.get_filters(params)
      filters = params.map do |k,v|
          "#{api_compatible_names([k])}#{url_encoded_value(v)}"
      end
      conditions.merge!({"filters" => filters.join(",")})
    end

    def self.get_metrics_and_dimensions(params)
      params.each do |k,v|
        conditions.merge!({"#{k}" => api_compatible_names(v)})
      end
    end

    def self.api_compatible_names(values)
      values.collect {|e| "ga:#{e}"}.join(",")
    end

    def self.extract_dates(params)
      start_date = params.delete(:start_date)
      end_date  = params.delete(:end_date)
      conditions.merge!({"start-date" => format_date(start_date)})
      conditions.merge!({"end-date" => format_date(end_date)})
    end

    def self.format_date(date)
      date.strftime("%Y-%m-%d")
    end

    def self.url_encoded_value(value)
      URI.escape(value, "=@!><")
    end
  end
end