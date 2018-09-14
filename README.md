# Dataclips


## DB Setup

```
rake dataclips:install:migrations
rake db:migrate
```

## Configuration
You can configure Dataclips' Insights with default params via configuration block
```ruby
Dataclips::Insight.configure do |config|
  config.default_params = { my_param: "my default value" }
end
```
and the `my_param` will always be there. You can easily override the default param by passing a param with the same name, like so:
```ruby
  Dataclips::Insight.get!("my_clip", my_param: "new value")
```

It is also possible to configure the default params with dynamic values by passing a callable object to them, e.g.
```ruby
Dataclips::Insight.configure do |config|
  config.default_params = { my_param: -> { Time.now } }
end
```
and the value will be evaluated on-the-fly.

## Mount engine (config/routes.rb)

```ruby
mount Dataclips::Engine => "/dataclips", as: :dataclips
```
