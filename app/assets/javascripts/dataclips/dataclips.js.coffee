class Dataclips.View extends Backbone.View
  events:
    "input input[type=text]": _.debounce (event) ->
      @filterArgs.set(event.target.name, $.trim(event.target.value))

  render: ->
    @filterArgs = new Backbone.Model

    options =
      enableColumnReorder: false
      forceFitColumns: true

    dataView = new Slick.Data.DataView()
    dataView.setFilterArgs(@filterArgs.toJSON())

    @listenTo @filterArgs, "change", (model, data) ->
      dataView.setFilterArgs(model.toJSON())
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

    grid = new Slick.Grid("#grid", dataView, columns, options)

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

    exactMatcher = (item, attr, query) ->
      return true unless query
      return true if _.isEmpty query.trim()
      item[attr] is query

    dataView.setFilter (item, args) ->
      _.all Dataclips.config.schema, (options, attr) ->
        switch options.type
          when "text"
            textFilter(item, attr, args[attr])
          else
            console.log item, args
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
  collection = new Dataclips.Records
  collection.url = @config.url

  view = new Dataclips.View(el: "#dataclip", collection: collection)

  view.render()
  collection.fetchInBatches(@config.params)
