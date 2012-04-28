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

```ruby
  analytics = Ariadna::Analytics.new(access_token)
```

Get a list of all accounts available

```ruby
  accounts    = analytics.accounts
```

Get a list of all web properties available for an account

```ruby
  properties = accounts.first.properties.all
```

Get a list of all profiles available for a web property

```ruby
  profiles    = properties.first.profiles.all
```

Create a query with your metrics and dimensions

```ruby
  results  = profile.results.select(
        :metrics    => [:visits, :bounces, :timeOnSite],
        :dimensions => [:country]
      )
      .where(
        :start_date => Date.today,
        :end_date   => 2.months.ago,
        :browser    => "==Firefox"
      )
      .limit(100)
      .offset(40)
      .order([:visits, :bounces])
      .all
```

All the metrics and dimensions returned by the query are mapped into attributes.

```ruby
  @results.each do |result|
    puts result.visits
    puts result.bounces
    puts result.timeonsite
    puts result.country
  end
```

### Create a connexion

  Ariadna::Analytics.new(access_token, proxy_settings, refresh_token_data)

  There are three possible params:

  access_token (mandatory): an oauth2 access token 

  proxy_settings (optional): a hash containing your proxy options

  refresh_token_data (optional): a hash with information about your app so access_token can be renewed automatically in case it is expired.

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

### Access token

Ariadna is agnostic about the way you get your Oauth2 access token.

For the development of this gem I've been using [Omiauth](https://github.com/intridea/omniauth) with the [Google Oauth2 strategy](https://github.com/zquestz/omniauth-google-oauth2)

```ruby
gem 'omniauth'

gem 'omniauth-google-oauth2'
```

Google Oauth2 tokens have a very short life.  To make things easy if the connexion gives a 401 error and there is a refresh token passed as a param Ariadna will try to get a new access token from Google and store it in the curren user info calling update_access_token_from_google.  If you want to use this feature you must create a method in your user model that saves this token.

```ruby
def update_access_token_from_google(new_token)
  update_attribute(:google_oauth2_token, new_token)
end
```

It is obviously out of the scope of this gem to update tokens but it is definetly something that will make your life easier.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Contributors

* Jorge Alvarez [http://www.alvareznavarro.es](http://www.alvareznavarro.es/?utm_source=github&utm_medium=gem&utm_campaign=ariadna)
