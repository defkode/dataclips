class Dataclips.View extends Backbone.View
  el: "body"
  events:
    "click a.fullscreen": ->
      @requestFullScreen(document.body)
      false

    "click a.reload": ->
      @reload()
      false

    "input input[type=text]": _.debounce (event) ->
      @filterArgs.set(event.target.name, $.trim(event.target.value))

    "change input.float[type=number]": _.debounce (event) ->
      value = parseFloat(event.target.value)
      if _.isNaN(value)
        @filterArgs.unset(event.target.name)
      else
        @filterArgs.set(event.target.name, value)

    "change input.integer[type=number]": _.debounce (event) ->
      value = parseInt(event.target.value)
      if _.isNaN(value)
        @filterArgs.unset(event.target.name)
      else
        @filterArgs.set(event.target.name, value)

    "change select.boolean": _.debounce (event) ->
      value = event.target.value
      if value is ""
        @filterArgs.unset(event.target.name)
      else
        @filterArgs.set(event.target.name, value is "1")

    "dp.change .input-group": _.debounce (event) ->
      value = event.date
      attrName = $(event.target).attr("rel")
      if value?
        @filterArgs.set(attrName, value)
      else
        @filterArgs.unset(attrName)

    "click button.reset": _.debounce (event) ->
      key = $(event.currentTarget).data("key")
      @resetFilter(key)


  resetFilter: (key) ->
    type = Dataclips.config.schema[key]["type"]
    switch type
      when "integer", "float", "decimal", "date", "datetime", "time"
        @$el.find("input[name=#{key}_from]").val("")
        @$el.find("input[name=#{key}_to]").val("")
        @filterArgs.unset("#{key}_from")
        @filterArgs.unset("#{key}_to")
      when "text"
        @$el.find("input[name=#{key}]").val("")
        @filterArgs.unset(key)
      when "boolean"
        @$el.find("select[name=#{key}]").val("")
        @filterArgs.unset(key)
      else
        @filterArgs.unset(key)

  resetAllFilters: ->
    _.each Dataclips.config.schema, (options, key) =>
      @resetFilter(key)

  reload: ->
    @collection.reset()
    @collection.fetchInBatches()


  moveProgressBar: (percentLoaded) ->
    $("#modal, #progress").toggle percentLoaded isnt 100


  requestFullScreen: (element) ->
    if (document.fullscreenEnabled || document.mozFullScreenEnabled || document.documentElement.webkitRequestFullScreen)
      if element.requestFullscreen
        element.requestFullscreen()
      else if element.mozRequestFullScreen
        element.mozRequestFullScreen()
      else if element.webkitRequestFullScreen
        element.webkitRequestFullScreen()

  render: ->
    @filterArgs = new Backbone.Model

    @listenTo Dataclips.proxy, "change", _.debounce (model) ->
      @$el.find("span.total_entries_count").text(model.get("total_entries_count"))
      @$el.find("span.entries_count").text(model.get("entries_count"))
      @$el.find("span.percent_loaded").text(model.get("percent_loaded"))
      @$el.find("span.grid_entries_count").text(model.get("grid_entries_count"))


    window.addEventListener 'message', (e) =>
      @reload() if e.data.refresh is true

      @requestFullScreen(document.body) if e.data.fullscreen is true

      if e.data.filters
        @resetAllFilters()

        _.each e.data.filters, (value, key) =>
          if Dataclips.config.schema[key]?
            type = Dataclips.config.schema[key]["type"]

            switch type
              when "boolean"
                if value?
                  $("[name='#{key}']").val(if value is true then "1" else "0")
                  @filterArgs.set(key, value)
              when "text"
                if value?
                  $("[name='#{key}']").val(value)
                  @filterArgs.set(key, value)
              when "float", "integer", "decimal"
                if value.from?
                  $("[name='#{key}_from']").val(value.from)
                  @filterArgs.set("#{key}_from", value.from)
                if value.to?
                  $("[name='#{key}_to']").val(value.to)
                  @filterArgs.set("#{key}_to", value.from)
              when "date", "datetime", "time"
                if value.from?
                  fromPicker = $("[rel='#{key}_from']")
                  fromPicker.data('DateTimePicker').date(moment(value.from))
                  @filterArgs.set("#{key}_from", moment(value.from).toDate())

                if value.to?
                  toPicker = $("[rel='#{key}_to']")
                  toPicker.data('DateTimePicker').date(moment(value.to))
                  @filterArgs.set("#{key}_to", moment(value.to).toDate())

    options =
      enableColumnReorder:        false
      forceFitColumns:            true
      enableTextSelectionOnCells: true

    dataView = new Slick.Data.DataView()
    dataView.setFilterArgs(@filterArgs.toJSON())

    @listenTo @filterArgs, "change", _.debounce (model, data) ->
      dataView.setFilterArgs(model.attributes)
      dataView.refresh()


    columns = []

    _.each Dataclips.config.schema, (options, attr) ->
      formatter = if options.formatter?
        options.formatter
      else
        options.type

      if options.grid is true
        columns.push
          focusable:      true
          field:          attr
          id:             attr
          name:           Dataclips.config.headers[attr]
          selectable:     false
          sortable:       options.sortable?
          cssClass:       options.type
          headerCssClass: options.type
          formatter:      Dataclips.Formatters[formatter]
          width:          options.width

    grid = new Slick.Grid("#grid", dataView, columns, options)

    grid.registerPlugin(new Slick.AutoTooltips(enableForHeaderCells: true));


    $(window).resize ->
      grid.resizeCanvas()

    # grid.onSelectedRowsChanged.subscribe (e, args) ->
    #    console.log(grid.getSelectedRows())

    # grid.setSelectionModel(new Slick.RowSelectionModel)

    grid.onSort.subscribe (e, args) ->
      sortcol = args.sortCol.field

      compareByColumn = (a, b) ->
        x = a[sortcol] || ""
        y = b[sortcol] || ""
        if x is y
          0
        else
          if x > y then 1 else -1

      dataView.sort(compareByColumn, args.sortAsc)

    textFilter = (item, attr, query) ->
      return true unless query
      return true if _.isEmpty query.trim()
      value = item[attr]

      return false unless value?

      value.toLowerCase().indexOf(query.toLowerCase()) != -1

    booleanFilter = (item, attr, selector) ->
      return true if selector is undefined # all
      selector is item[attr]

    numericFilter = (item, attr, range) ->
      value = item[attr]
      return true if value is undefined
      if range.from? || range.to?
        gte = (from) ->
          return true if from is undefined
          value >= from

        lte = (to) ->
          return true if to is undefined
          value <= to

        gte(range.from) && lte(range.to)
      else
        true

    dateFilter = (item, attr, range) ->
      value = item[attr]
      return true if value is undefined
      if range.from? || range.to?
        gte = (from) ->
          return true if from is undefined
          value >= from

        lte = (to) ->
          return true if to is undefined
          value <= to

        gte(range.from) && lte(range.to)
      else
        true

    exactMatcher = (item, attr, query) ->
      return true unless query
      return true if _.isEmpty query.trim()
      item[attr] is query

    dataView.setFilter (item, args) ->
      _.all Dataclips.config.schema, (options, attr) ->
        switch options.type
          when "text"
            textFilter(item, attr, args[attr])
          when "integer", "float", "decimal"
            numericFilter(item, attr, {
              from: args["#{attr}_from"],
              to:   args["#{attr}_to"]
            })
          when "datetime", "date"
            dateFilter(item, attr, {
              from: args["#{attr}_from"],
              to:   args["#{attr}_to"]
            })
          when "boolean"
            booleanFilter(item, attr, args[attr])
          else
            true

    # pageSize, pageNum, totalRows, totalPages
    dataView.onPagingInfoChanged.subscribe (e, args) ->
      Dataclips.proxy.set
        grid_entries_count: args.totalRows
        grid_entries: _.map [0..(args.totalRows - 1)], (id) -> dataView.getItem(id) # not safe

    # previous, current
    dataView.onRowCountChanged.subscribe (e, args) ->
      grid.updateRowCount()
      grid.render()

    # rows
    dataView.onRowsChanged.subscribe (e, args) ->
      grid.invalidateRows(args.rows)
      grid.render()

    updateDataView = (data) ->
      dataView.beginUpdate()
      dataView.setItems(data)
      dataView.endUpdate()

    @listenTo @collection, "reset batchInsert", ->
      updateDataView @collection.toJSON()


    unless Modernizr.input.list
      $('input[list]').relevantDropdown({
        fadeOutSpeed: 0
      })



