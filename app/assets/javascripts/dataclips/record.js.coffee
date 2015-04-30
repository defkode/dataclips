class Dataclips.Record extends Backbone.Model
  parse: (options) ->
    attributes = _.reduce options, (memo, value, key) ->
      memo[key] = switch Dataclips.config.schema[key].type
        when "datetime", "time", "date"
          moment(value) if value?
        else
          value

      memo
    , {}

    attributes.id = @cid
    super(attributes)
