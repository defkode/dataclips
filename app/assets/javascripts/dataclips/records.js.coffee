class Dataclips.Records extends Backbone.Collection
  model: Dataclips.Record
  fetchInBatches: (defaultParams = {}) ->
    fetchNextPage = (collection, current_page, total_pages) ->
      if current_page < total_pages
        collection.fetch
          data: _({page: current_page + 1}).extend(defaultParams),
          remove: false,
          success: (collection, data) ->
            collection.trigger "batchInsert", data
            fetchNextPage(collection, data.page, data.total_pages)


    @fetch
      data: defaultParams
      success: (collection, data) ->
        collection.trigger "batchInsert", data
        fetchNextPage(collection, data.page, data.total_pages)
      error: (collection, response) ->
        alert(response.responseText)

  parse: (data) -> data.records
