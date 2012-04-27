require 'sqlite3'

module Ariadna
  #Sqlite3 in memoroy connector to simulate Zuora in test environments
  class SqliteConnector
    class << self
      attr_accessor :db
    end

    def initialize(token, proxy_options, refresh_token_options)
      build_schema
    end

    def get_url(url)
      if url.include? "data/ga"
        #results
      elsif url.include? "goals"
        #goals
      elsif url.include? "profiles"
        #profiles
      elsif url.include? "webproperties"
        #webproperties
      elsif url.include? "accounts"
        get_all_accounts
      end
    end

    def query(sql)
      result = db.query sql
      hashed_result = result.map {|r| hash_result_row(r, result) }
      {
        :query_response => {
          :result => {
            :success => true,
            :size => result.count,
            :records => hashed_result
          }
        }
      }
    end

    def create
      table = self.class.table_name(@model.class)
      hash = @model.to_hash
      hash.delete(:id)
      keys = []
      values = []
      hash.each do |key, value|
        keys << key.to_s.camelize
        values << value.to_s
      end
      place_holder = ['?'] * keys.length
      keys = keys.join(', ')
      place_holder = place_holder.join(', ')
      insert = "INSERT into '#{table}'(#{keys}) VALUES(#{place_holder})"
      db.execute insert, values
      new_id = db.last_insert_row_id
      {
        :create_response => {
          :result => {
            :success => true,
            :id => new_id
          }
        }
      }
    end

    def update
      table  = self.class.table_name(@model.class)
      hash   = @model.to_hash
      id     = hash.delete(:id)
      keys   = []
      values = []
      hash.each do |key, value|
        keys << "#{key.to_s.camelize}=?"
        values << value.to_s
      end
      keys   = keys.join(', ')
      update = "UPDATE '#{table}' SET #{keys} WHERE ID=#{id}"
      db.execute update, values
      {
        :update_response => {
          :result => {
            :success => true,
            :id => id
          }
        }
      }
    end

    def destroy
      table = self.class.table_name(@model.class)
      destroy = "DELETE FROM '#{table}' WHERE Id=?"
      db.execute destroy, @model.id
      {
        :delete_response => {
          :result => {
            :success => true,
            :id => @model.id
          }
        }
      }
    end

    def parse_attributes(type, attrs = {})
      data = attrs.to_a.map do |a|
        key, value = a
        [key.underscore, value]
      end
      Hash[data]
    end

    def build_schema
      @db = SQLite3::Database.new ":memory:"
      generate_tables
    end

    def self.table_name(model)
      model.name.demodulize
    end

    protected

    def hash_result_row(row, result)
      row = row.map {|r| r.nil? ? "" : r }
      Hash[result.columns.zip(row.to_a)]
    end

    def generate_tables
      models = Ariadna.constants
      models = models - [:VERSION, :Delegator, :SqliteConnector]
      models.each do |model|
        create_table(model)
      end
    end

    def create_table(model)
      obj = eval(model.to_s)
      table_name = model.to_s
      attributes = obj.instance_methods - Object.instance_methods - [:id]
      attributes = attributes.map do |a|
        "'#{a.to_s.camelize}' text"
      end
      autoid = "'Id' integer PRIMARY KEY AUTOINCREMENT"
      attributes.unshift autoid
      attributes = attributes.join(", ")
      schema = "CREATE TABLE 'main'.'#{table_name}' (#{attributes});"
      @db.execute schema
    end

    def get_all_accounts
      result        = @db.execute "SELECT * FROM ACCOUNT"
      puts result
      hashed_result = result.map {|r| hash_result_row(r, result) }
      puts "--------------------"
      puts hashed_result
      {
        "kind"          => "analytics#accounts",
        "username"      => "username",
        "totalResults"  => 100,
        "startIndex"    => 1,
        "itemsPerPage"  => 1000,
        "previousLink"  => "www",
        "nextLink"      => "www",
        "items"         => [hashed_result]
      }
    end

  end
end
