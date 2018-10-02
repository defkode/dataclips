# Dataclips


## DB Setup

```
rake dataclips:install:migrations
rake db:migrate
```

## Mount engine (config/routes.rb)

```ruby
mount Dataclips::Engine => "/dataclips", as: :dataclips
```
