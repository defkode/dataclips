window.Dataclips = {}

class Dataclips.Record extends Backbone.Model
  parse: (options) ->
    options.id = @cid
    super(options)


class Dataclips.Records extends Backbone.Collection
  model: Dataclips.Record
  fetchInBatches: (defaultParams = {}) ->

    fetchNextPage = (collection, current_page, total_pages) ->
      if current_page < total_pages
        collection.fetch
          data: _({page: current_page + 1}).extend(defaultParams),
          remove: false,
          success: (collection, data) ->
            collection.trigger "batchInsert", data.orders
            fetchNextPage(collection, data.page, data.total_pages)

    @fetch
      data: defaultParams
      success: (collection, data) ->
        $("span.total_entries").text(data.total_entries)
        collection.trigger "batchInsert", data.records
        fetchNextPage(collection, data.page, data.total_pages)
      error: (collection, response) ->
        alert(response.responseText)

  parse: (data) -> data.records

class Dataclips.View extends Backbone.View
  events:
    "keyup input[type=text]": (event) ->
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
      columns.push
        field: attr
        id: attr
        name: Dataclips.config.headers[attr]
        sortable: true
        cssClass: options.type
        headerCssClass: options.type

    grid = new Slick.Grid("#grid", dataView, columns, options)

    # grid.setSortColumn("date", false)

    grid.onSort.subscribe (e, args) ->
      sortcol = args.sortCol.field

      compareByColumn = (a, b) ->
        x = a[sortcol]
        y = b[sortcol]
        if x is y
          0
        else
          if x > y then 1 else -1

      dataView.sort(compareByColumn, args.sortAsc)

    textFilter = (item, attr, query) ->
      return true unless query
      return true if query.isBlank()
      item[attr].has(query)

    dataView.setFilter (item, args) ->
      _.all Dataclips.config.schema, (options, attr) ->
        switch options.type
          when "string", "text" then textFilter(item, attr, args[attr])
          else true

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
