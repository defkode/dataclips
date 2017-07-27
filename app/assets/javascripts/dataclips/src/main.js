$          = jQuery = require('jquery');
_          = require('underscore');

// Moment
moment = require("moment");

// Backbone
Backbone   = require('backbone');
Backbone.$ = $;

Dataclips         = require('./dataclips');
Records           = require('./records');

Dataclips.Progress    = require('./progress');
Dataclips.GridView    = require('./views/grid');
Dataclips.SidebarView = require('./views/sidebar')

Dataclips.resetFilter = function(key) {
  var type = Dataclips.config.schema[key]["type"];

  switch (type) {
    case "integer":
    case "float":
    case "decimal":
    case "date":
    case "datetime":
    case "time":
      Dataclips.filterArgs.unset(key + "_from");
      Dataclips.filterArgs.unset(key + "_to");
      break;
    default:
      Dataclips.filterArgs.unset(key);
  }
}

Dataclips.resetAllFilters = function(){
  _.each(Dataclips.config.schema, function(options, key) {
    Dataclips.resetFilter(key)
  });
};

Dataclips.reload = function(){
  Dataclips.collection.reset();
  Dataclips.collection.fetchInBatches();
};

Dataclips.requestFullScreen = function(element) {
  if (document.fullscreenEnabled || document.mozFullScreenEnabled || document.documentElement.webkitRequestFullScreen) {
    if (element.requestFullscreen) {
      return element.requestFullscreen();
    } else if (element.mozRequestFullScreen) {
      return element.mozRequestFullScreen();
    } else if (element.webkitRequestFullScreen) {
      return element.webkitRequestFullScreen();
    }
  }
};


Dataclips.resizeGrid = function(){
  var grid    = document.getElementById('grid');
  grid.style.height = window.innerHeight + 'px';
};

Dataclips.run = function(){
  Dataclips.collection     = new Records;
  Dataclips.collection.url = this.config.url;

  this.gridView      = new Dataclips.GridView({collection: Dataclips.collection});
  this.sidebarView   = new Dataclips.SidebarView;
  this.progress      = new Dataclips.Progress();

  Dataclips.collection.on("reset", function() {
    Dataclips.proxy.clear();
  });

  Dataclips.collection.on("batchInsert", function(data){
    var total_entries_count = data.total_entries_count;
    var entries_count       = Dataclips.collection.size();
    var percent_loaded      = entries_count > 0 ? (entries_count / total_entries_count) : total_entries_count === 0 ? 1 : 0;

    Dataclips.progress.moveProgressBar(percent_loaded);

    Dataclips.proxy.set({
      total_entries_count: total_entries_count,
      entries_count:       entries_count,
      percent_loaded:      percent_loaded,
      batch:               data.records
    });
  });

  Dataclips.collection.fetchInBatches(this.config.params);

  this.gridView.render();
  this.progress.render();
  this.sidebarView.render();

  $(window).trigger('resize');
};


window.addEventListener('message', function(e) {
  if (e.data.refresh    === true) { Dataclips.reload() }
  if (e.data.fullscreen === true) { Dataclips.requestFullScreen(document.body) }

  if (e.data.filters) {
    Dataclips.resetAllFilters();

    _.each(e.data.filters, function(value, key) {
      if (Dataclips.config.schema[key] != null) {
        var type = Dataclips.config.schema[key]["type"];
        switch (type) {
          case "boolean":
            if (value != null) { Dataclips.filterArgs.set(key, value) }
            break;
          case "text":
            if (value != null) { Dataclips.filterArgs.set(key, value) }
            break;
          case "float":
          case "integer":
          case "decimal":
            if (value.from != null) { Dataclips.filterArgs.set(key + "_from", value.from) }
            if (value.to != null)   { Dataclips.filterArgs.set(key + "_to", value.from) }
            break;
          case "date":
          case "datetime":
          case "time":
            if (value.from != null) { Dataclips.filterArgs.set(key + "_from", moment(value.from).toDate()) }
            if (value.to != null)   { Dataclips.filterArgs.set(key + "_to", moment(value.to).toDate()) }
            break;
        }
      } else {
        if (key === "query") { Dataclips.filterArgs.set("query", value) }
      }
    });
  }

});

