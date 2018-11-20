Rails = require('rails-ujs');

require('../../vendor/slickgrid/lib/jquery.event.drag-2.2');

require('../../vendor/slickgrid/slick.core');
require('../../vendor/slickgrid/slick.grid');
require('../../vendor/slickgrid/slick.dataview');

require('../../vendor/slickgrid/plugins/slick.autotooltips');
require('../../vendor/slickgrid/plugins/slick.rowselectionmodel');

# Modernizr
require("../../vendor/modernizr")
require("../../vendor/polyfills/datalist")

# DownloadJS
downloader = require("downloadjs")
Dataclips.buildXLSX = require('../xlsx')

filters  = require('../filters');

module.exports = Backbone.View.extend
  el: "body"

  events:
    "click #download-dialog .btn.btn-primary": _.debounce (e) ->
      button = Backbone.$(e.target)

      if @$el.find(".tab-pane.active").attr("id") is "xlsx"
        button.prop("disabled", true).blur().find("i").show()
        filename = Backbone.$('#filename_xlsx').val() + '.xlsx'
        setTimeout =>
          Dataclips.buildXLSX().then (file) =>
            @modal.modal('hide');
            button.prop("disabled", false).find("i").hide()
            downloader(file, filename, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
        , 100
      else
        # csv
        @modal.modal('hide')
        Backbone.$("#download-dialog form").submit()

    "click a.download": (e) ->
      if Modernizr.adownload
        e.preventDefault()
        @modal.modal('show')
        Backbone.$('#xlsx').tab('show')

  initialize: ->
    Dataclips.resizeGrid()

  render: ->
    @listenTo Dataclips.proxy, "change", _.debounce (model) ->
      @$el.find("span.total_entries_count").text(model.get("total_entries_count"))
      @$el.find("span.entries_count").text(model.get("entries_count"))
      @$el.find("span.percent_loaded").text(model.get("percent_loaded"))
      @$el.find("span.grid_entries_count").text(model.get("grid_entries_count"))

    @configureSlickGrid()

    @modal = $("#download-dialog").modal('hide')

    Rails.start()


  configureSlickGrid: ->
    options =
      enableColumnReorder:        false
      forceFitColumns:            true
      enableTextSelectionOnCells: true
      rowHeight:                  Dataclips.config.row_height

    dataView = new Slick.Data.DataView()
    dataView.setFilterArgs(Dataclips.filterArgs.toJSON())

    @listenTo Dataclips.filterArgs, "change", _.debounce (model, data) ->
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
          autoHeight:     true

    grid = new Slick.Grid("#grid", dataView, columns, options)

    grid.registerPlugin(new Slick.AutoTooltips(enableForHeaderCells: true));


    Backbone.$(window).on 'resize', ->
      Dataclips.resizeGrid()
      grid.resizeCanvas()

    # grid.setSelectionModel(new Slick.RowSelectionModel)

    # grid.onSelectedRowsChanged.subscribe (e, args) ->
    #    console.log(grid.getSelectedRows())


    grid.onClick.subscribe (e, args) ->
      Dataclips.proxy.set('row-clicked', dataView.getItem(args.row))

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


    dataView.setFilter (item, args) ->
      query = args.query?.trim()

      and_conditions = _.all Dataclips.config.schema, (options, attr) ->
        switch options.type
          when "text"
            filters.textFilter(item, attr, args[attr])
          when "integer", "float", "decimal", "datetime", "date"
            filters.numericFilter(item, attr, {
              from: args["#{attr}_from"],
              to:   args["#{attr}_to"]
            })
          when "boolean"
            filters.booleanFilter(item, attr, args[attr])
          else
            true

      if _.isEmpty(query)
         and_conditions
      else
        searchableKeys = []
        _(Dataclips.config.schema).each (attrs, key) ->
          if attrs.type is "text" && !_(args).has(key)
            searchableKeys.push(key)

        and_conditions && _.any searchableKeys, (key) -> filters.textFilter(item, key, query)

    # pageSize, pageNum, totalRows, totalPages
    dataView.onPagingInfoChanged.subscribe (e, args) ->
      Dataclips.proxy.set
        grid_entries_count: args.totalRows
        grid_entries: _.map [0..(args.totalRows - 1)], (id) -> _.omit dataView.getItem(id), "id" # not safe

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
      Backbone.$('input[list]').relevantDropdown({
        fadeOutSpeed: 0
      })



