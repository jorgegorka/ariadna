# Ariadna

Google Analytics API wrapper.

It uses Oauth2 as authorization

## Installation

Add this line to your application's Gemfile:

gem 'ariadna'

And then execute:

$ bundle

Or install it yourself as:

$ gem install ariadna

## Usage

Create a new connexion with your Oauth2 access token

<pre>
```ruby
  analytics = Ariadna::Analytics.new(access_token)
```  
</pre>

Get a list of all accounts available

<pre>
```ruby
  accounts    = analytics.accounts
```  
</pre>

Get a list of all web properties available for an account

<pre>
```ruby
  properties = accounts.first.properties.all
```  
</pre>

Get a list of all profiles available for a web property
  
<pre>
```ruby
  profile    = properties.first.profiles.all.first
```  
</pre>

Create a query with your metrics and dimensions
  
<pre>
```ruby
  results  = @profile.results.where(
    "start-date" => 10.days.ago.strftime("%Y-%m-%d"),
    "end-date"   => 1.day.ago.strftime("%Y-%m-%d"),
    "metrics"    => "ga:visits,ga:bounces,ga:timeOnSite"
  ).order("visits")
```  
</pre>
  
All the metrics and dimensions returned by the query are mapped into attributes.
In this particular query yo can get visits, bounces and timeOnSite

<pre>
```ruby
  @results.each do |result|
    result.visits
    result.bounces
    result.timeonsite
  end
```  
</pre>

### Create a connexion

  Ariadna::Analytics.new(access_token, proxy_settings, refresh_token_data)

  There are three possible params:
  
  access_token (mandatory): an oauth2 access token 
  
  proxy_settings (optional): a hash containing your proxy options
  
  refresh_token_data (optional): a hash with information about your app so access_token can be renewed automatically in case it is expired.
  
<pre>
```ruby
  analytics = Ariadna::Analytics.new(
    access_token,
    { proxy_host: 'proxy.yourproxy.com',
      proxy_port: 8080,
      proxy_user: 'username',
      proxy_pass: 'password'
     },
    # Google access tokens are short term so chances are you are going to need to refresh them
    { refresh_token: analytics_refresh_token,
      client_id: 'apps.googleusercontent.com',
      client_secret: 'client_secret',
      current_user:  current_user
    }
  )
```  
</pre>

### Access token

Ariadna is agnostic about the way you get your Oauth2 access token.

For the development of this gem I've been using [Omiauth](https://github.com/intridea/omniauth) with the [Google Oauth2 strategy](https://github.com/zquestz/omniauth-google-oauth2)

<pre>
gem 'omniauth'

gem 'omniauth-google-oauth2'
</pre>


  
## Contributing
 
1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Contributors

* Jorge Alvarez [http://www.alvareznavarro.es](http://www.alvareznavarro.es)