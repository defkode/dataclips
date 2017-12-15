Record  = require('./record');

module.exports = Backbone.Collection.extend({
  model: Record,
  fetchInBatches: function(defaultParams) {
    if (defaultParams == null) { defaultParams = {}; }

    var onSuccess = function(collection, records, options) {
      var total_entries_count = parseInt(options.xhr.getResponseHeader('x-total-count'), 10);
      var current_page        = parseInt(options.xhr.getResponseHeader('x-page'), 10);
      var total_pages         = parseInt(options.xhr.getResponseHeader('x-total-pages'), 10);

      collection.trigger("batchInsert", records, total_entries_count);

      if (current_page < total_pages) {
        fetchNextPage(collection, current_page + 1);
      }
    }

    var fetchNextPage = function(collection, page) {
      collection.fetch({
        data: _({page: page}).extend(defaultParams),
        remove: false,
        success: onSuccess
      })
    };

    this.fetch({
      data: defaultParams,
      success: onSuccess,
      error: function(collection, response) {
        if (response.status) {
          alert(response.responseText);
        }
      }
    });
  }
});
