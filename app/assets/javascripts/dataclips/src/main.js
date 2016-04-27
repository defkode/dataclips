$          = jQuery = require('jquery');
_          = require('underscore');

// Modernizr
require("../vendor/modernizr")
require("../vendor/polyfills/datalist")

// Backbone
Backbone   = require('backbone');
Backbone.$ = $;

Dataclips         = require('./dataclips');
Records           = require('./records');

Dataclips.Progress = require('./progress');
Dataclips.View     = require('./view');

Dataclips.run = function(){
  var collection     = new Records;
  collection.url     = this.config.url;
  this.view           = new Dataclips.View({collection: collection});
  this.progress       = new Dataclips.Progress();

  collection.on("reset", function() {
    Dataclips.proxy.clear();
  });

  collection.on("batchInsert", function(data){
    var total_entries_count = data.total_entries_count;
    var entries_count       = collection.size();
    var percent_loaded      = entries_count > 0 ? (entries_count / total_entries_count) : total_entries_count === 0 ? 1 : 0;

    Dataclips.progress.moveProgressBar(percent_loaded);

    Dataclips.proxy.set({
      total_entries_count: total_entries_count,
      entries_count:       entries_count,
      percent_loaded:      percent_loaded,
      batch:               data.records
    });
  });

  collection.fetchInBatches(this.config.params);

  this.progress.render();
  this.view.render();
};
