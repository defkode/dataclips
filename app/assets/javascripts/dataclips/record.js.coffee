class Dataclips.Record extends Backbone.Model
  parse: (options) ->
    options.id = @cid
    super(options)
