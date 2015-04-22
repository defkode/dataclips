class Dataclips.View extends Backbone.View
  events:
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

    "dp.change .input-group": _.debounce (event) ->
      value = event.date
      attrName = $(event.target).attr("rel")
      if value?
        @filterArgs.set(attrName, value)
      else
        @filterArgs.unset(attrName)

    "click button.reset": _.debounce (event) ->
      key = $(event.currentTarget).data("key")
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
        else
          @filterArgs.unset(key)


  moveProgressBar: (percentLoaded) ->
    $("#modal, #progress").toggle percentLoaded isnt 100

  render: ->
    @filterArgs = new Backbone.Model

    options =
      enableColumnReorder: false
      forceFitColumns: true

    dataView = new Slick.Data.DataView()
    dataView.setFilterArgs(@filterArgs.toJSON())

    @listenTo @filterArgs, "change", (model, data) ->
      dataView.setFilterArgs(model.attributes)
      dataView.refresh()

    columns = []

    _.each Dataclips.config.schema, (options, attr) ->
      formatter = if options.formatter?
        options.formatter
      else
        options.type

      columns.push
        focusable:      true
        field:          attr
        id:             attr
        name:           Dataclips.config.headers[attr]
        sortable:       options.sortable?
        cssClass:       options.type
        headerCssClass: options.type
        formatter:      Dataclips.Formatters[formatter]
        width:          options.width

    grid = new Slick.Grid("#grid", dataView, columns, options)

    grid.registerPlugin(new Slick.AutoTooltips(enableForHeaderCells: true));

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
      item[attr]?.toLowerCase().indexOf(query.toLowerCase()) != -1

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
          else
            true

    dataView.onRowCountChanged.subscribe (e, args) ->
      grid.updateRowCount()
      grid.render()

    dataView.onRowsChanged.subscribe (e, args) ->
      grid.invalidateRows(args.rows)
      grid.render()


    dataView.onPagingInfoChanged.subscribe (e, args) ->
      $("span.count").text(args.totalRows)

    updateDataView = (data) ->
      dataView.beginUpdate()
      dataView.setItems(data)
      dataView.endUpdate()

    @listenTo @collection, "batchInsert", ->
      updateDataView(@collection.toJSON())

Dataclips.run = ->
  window.addEventListener 'message', (event) ->
    mainWindow = event.source


  bg = $('#progress').get(0)
  ctx = bg.getContext('2d')
  imd = null;
  circ = Math.PI * 2
  quart = Math.PI / 2

  ctx.beginPath()
  ctx.strokeStyle = '#99CC33'
  ctx.lineCap = 'square'
  ctx.closePath()
  ctx.fill()
  ctx.lineWidth = 20.0

  imd = ctx.getImageData(0, 0, 240, 240)

  draw = (current) ->
    ctx.putImageData(imd, 0, 0)
    ctx.beginPath()
    ctx.arc(120, 120, 70, -(quart), ((circ) * current) - quart, false)
    ctx.stroke()

  collection = new Dataclips.Records

  collection.url = @config.url

  view = new Dataclips.View(el: "#dataclip", collection: collection)

  collection.on "batchInsert", (data) ->
    total_entries = data.total_entries
    entries_count = collection.size()
    percent_loaded = if entries_count > 0 then Math.round((entries_count / total_entries) * 100) else 0

    view.moveProgressBar(percent_loaded)
    draw(percent_loaded / 100)

    window.parent.postMessage
      total_entries: total_entries
      entries_count: entries_count,
      percent_loaded: percent_loaded
    , "*"


  collection.fetchInBatches(@config.params)
  view.render()
