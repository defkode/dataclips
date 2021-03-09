# Dataclips


## DB Setup

```
rails dataclips:install:migrations
rails db:migrate
```

## Mount engine (config/routes.rb)

```ruby
mount Dataclips::Engine, at: "/dataclips", as: :dataclips
```
