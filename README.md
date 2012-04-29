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
  accounts    = analytics.accounts.all
```

Get a list of all web properties available for an account

```ruby
  properties = accounts.first.properties.all
```

Get a list of all profiles available for a web property

```ruby
  profiles    = properties.first.profiles.all
```

Create a query with metrics and dimensions

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
  results.each do |result|
    puts result.visits
    puts result.bounces
    puts result.timeOnSite
    puts result.country
  end
```

## More info

### [Table of Contents](https://github.com/jorgegorka/ariadna/wiki/Table-of-Contents)

## Contributors

* Jorge Alvarez [http://www.alvareznavarro.es](http://www.alvareznavarro.es/?utm_source=github&utm_medium=gem&utm_campaign=ariadna)