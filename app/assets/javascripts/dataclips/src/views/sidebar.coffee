require("bootstrap")

module.exports = Backbone.View.extend
  el: "#filters"
  events:
    "click a.fullscreen": ->
      Dataclips.requestFullScreen(document.body)
      false

    "click a.reload": ->
      Dataclips.reload()
      false

    "input input[type=text]": _.debounce (event) ->
      Dataclips.filterArgs.set(event.target.name, $.trim(event.target.value))

    "change input.float[type=number]": _.debounce (event) ->
      value = parseFloat(event.target.value)
      if _.isNaN(value)
        Dataclips.filterArgs.unset(event.target.name)
      else
        Dataclips.filterArgs.set(event.target.name, value)

    "change input.integer[type=number]": _.debounce (event) ->
      value = parseInt(event.target.value)
      if _.isNaN(value)
        Dataclips.filterArgs.unset(event.target.name)
      else
        Dataclips.filterArgs.set(event.target.name, value)

    "change select.boolean": _.debounce (event) ->
      value = event.target.value
      if value is ""
        Dataclips.filterArgs.unset(event.target.name)
      else
        Dataclips.filterArgs.set(event.target.name, value is "1")

    "dp.change .input-group": _.debounce (event) ->
      value = event.date
      attrName = $(event.target).attr("rel")
      if value?
        Dataclips.filterArgs.set(attrName, value)
      else
        Dataclips.filterArgs.unset(attrName)

    "click button.reset": _.debounce (event) ->
      key = $(event.currentTarget).data("key")
      Dataclips.resetFilter(key)

      type = Dataclips.config.schema[key]["type"]
      switch type
        when "integer", "float", "decimal", "date", "datetime", "time"
          @$el.find("input[name=#{key}_from]").val("")
          @$el.find("input[name=#{key}_to]").val("")
        when "text"
          @$el.find("input[name=#{key}]").val("")
        when "boolean"
          @$el.find("select[name=#{key}]").val("")
