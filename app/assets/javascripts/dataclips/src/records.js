Record  = require('./record');

module.exports = Backbone.Collection.extend({
  model: Record,
  fetchInBatches: function(defaultParams) {
    if (defaultParams == null) { defaultParams = {}; }

    var fetchNextPage = function(collection, current_page, total_pages) {
      if (current_page < total_pages) {
        collection.fetch({
          data: _({page: current_page + 1}).extend(defaultParams),
          remove: false,
          success: function(collection, data) {
            collection.trigger("batchInsert", data);
            fetchNextPage(collection, data.page, data.total_pages);
          }
        })
      }
    };

    this.fetch({
      data: _({timestamp: new Date().getTime()}).extend(defaultParams),
      success: function(collection, data) {
        collection.trigger("batchInsert", data);
        fetchNextPage(collection, data.page, data.total_pages);
      },
      error: function(collection, response) {
        if (response.status) {
          alert(response.responseText);
        }
      }
    });
  },
  parse: function(data) {
    return data.records;
  }
});
