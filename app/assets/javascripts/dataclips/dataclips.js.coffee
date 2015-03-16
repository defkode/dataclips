window.Dataclips = {}

Dataclips.Formatters =
  text:      (row, cell, value, columnDef, context) -> value
  integer:   (row, cell, value, columnDef, context) -> value
  float:     (row, cell, value, columnDef, context) -> value
  decimal:   (row, cell, value, columnDef, context) -> value
  date:      (row, cell, value, columnDef, context) -> value
  time:      (row, cell, value, columnDef, context) -> value
  datetime:  (row, cell, value, columnDef, context) ->
    value.long()
  binary:    (row, cell, value, columnDef, context) -> value
  boolean:   (row, cell, value, columnDef, context) ->
    if value is true then "&#9679" else "&#9675;"

  email:     (row, cell, value, columnDef, context) ->
    "<a href='mailto:#{value}'>#{value}</a>"

class Dataclips.Record extends Backbone.Model
  parse: (options) ->
    attributes = _.reduce options, (memo, value, key) ->
      memo[key] = switch Dataclips.config.schema[key].type
        when "datetime", "time", "date"
          new Date Date.parse(value)
        else
          value

      memo
    , {}

    attributes.id = @cid
    super(attributes)


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
    "keyup input.fuzzy[type=text]": (event) ->
      @filterArgs.set(event.target.name, $.trim(event.target.value))

    "typeahead:selected input.typeahead[type=text]": (event) ->
      @filterArgs.set(event.target.name, event.target.value)

    "typeahead:autocompleted input.typeahead[type=text]": (event) ->
      @filterArgs.set(event.target.name, event.target.value)

    "typeahead:closed input.typeahead[type=text]": (event) ->
      # console.log("closed")

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
      return true if query.isBlank()
      item[attr]?.toLowerCase().has(query.toLowerCase())

    exactMatcher = (item, attr, query) ->
      return true unless query
      return true if query.isBlank()
      item[attr] is query

    dataView.setFilter (item, args) ->
      _.all Dataclips.config.schema, (options, attr) ->
        switch options.type
          when "text"
            if options.dictionary
              exactMatcher(item, attr, args[attr])
            else
              textFilter(item, attr, args[attr])
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
  Date.setLocale(Dataclips.config.locale);
  collection = new Dataclips.Records
  collection.url = @config.url

  view = new Dataclips.View(el: "#dataclip", collection: collection)

  view.render()
  collection.fetchInBatches(@config.params)
