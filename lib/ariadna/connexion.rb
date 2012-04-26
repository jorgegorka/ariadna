require 'net/http'

module Ariadna
  class Connexion

    def initialize(token, proxy_options, refresh_info)
      @token = token
      extract_proxy_options(proxy_options) if proxy_options
      extract_refresh_info(refresh_info) if refresh_info
    end

    def get_url(url, params=nil)
      uri    = URI(url)
      headers = Hash.new
      resp = get_conn(uri)

      case resp
      # response is ok
      when Net::HTTPSuccess, Net::HTTPRedirection
        parse_response(resp)
      # if we have a refresh token we can ask for a new access token
      when Net::HTTPUnauthorized
        get_url(url) if @refresh_token and get_access_token     
      when Net::HTTPBadRequest
        ["bad request", uri]
      when Net::HTTPNotFound
        ["not found", uri]
      else
        resp.value
      end

    end

    private

    def extract_proxy_options(proxy_options)
      return if !proxy_options
      @use_proxy  = true
      @proxy_host = proxy_options[:proxy_host]
      @proxy_port = proxy_options[:proxy_port]
      @proxy_user = proxy_options[:proxy_user]
      @proxy_pass = proxy_options[:proxy_pass]
    end

    def extract_refresh_info(refresh_info)
      return if !refresh_info
      @refresh_token = refresh_info[:refresh_token]
      @client_id     = refresh_info[:client_id]
      @client_secret = refresh_info[:client_secret]
      @current_user  = refresh_info[:current_user]
    end

    # refresh access token as google access tokens have short term live
    def get_access_token
      uri = URI("https://accounts.google.com/o/oauth2/token")
      req                  = Net::HTTP::Post.new(uri.request_uri)
      req.set_form_data(
        'client_id'     => @client_id, 
        'client_secret' => @client_secret,
        'refresh_token' => @refresh_token,
        'grant_type'    => 'refresh_token'
      )
      if @use_proxy 
        conn = Net::HTTP::Proxy(@proxy_host, @proxy_port, @proxy_user, @proxy_pass).start(uri.hostname, uri.port) {|http|
          http.request(req)
        }
      else 
        conn = Net::HTTP.new(uri.host, uri.port)
        conn.request(req) 
      end

      case conn
      # response is ok
      when Net::HTTPSuccess, Net::HTTPRedirection
        # use the new access token 
        refresh_info              = parse_response(conn)
        @token                    = refresh_info["access_token"]
        @current_user.analytics_token = @token
        return @current_user.save
      # if not allowed revoke access
      when Net::HTTPUnauthorized
        @refresh_token = nil
      else
        conn
      end
      return false
    end

    def get_conn(uri)
      if @use_proxy
        req                  = Net::HTTP::Get.new(uri.request_uri)
        req["Authorization"] = "Bearer #{@token}"
        res = Net::HTTP::Proxy(@proxy_host, @proxy_port, @proxy_user, @proxy_pass).start(uri.hostname, uri.port) {|http|
          http.request(req)
        }
        res
      else 
        conn = Net::HTTP.new(uri.host, uri.port)
        # req                  = Net::HTTP::Get.new(uri.path)
        # req["Authorization"] = "Bearer #{@token}"
        conn.request(req) 
      end
    end

    def parse_response(resp)
      JSON.parse resp.body
    end

    def set_params(params)
      {}
    end
  end
end