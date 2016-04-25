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
Dataclips.View    = require('./view')

Dataclips.run = function(){

  var bg, circ, collection, ctx, draw, imd, quart, view;
  bg = $('#progress').get(0);
  ctx = bg.getContext('2d');
  imd = null;
  circ = Math.PI * 2;
  quart = Math.PI / 2;
  ctx.beginPath();
  ctx.strokeStyle = '#6F5498';
  ctx.closePath();
  ctx.fill();
  ctx.lineWidth = 10.0;
  imd = ctx.getImageData(0, 0, 240, 240);

  draw = function(current) {
    ctx.putImageData(imd, 0, 0);
    ctx.beginPath();
    ctx.arc(120, 120, 70, -quart, (circ * current) - quart, false);
    return ctx.stroke();
  };

  collection = new Records;
  collection.url = this.config.url;
  view = new Dataclips.View({
    collection: collection
  });
  collection.on("reset", function() {
    return Dataclips.proxy.clear();
  });
  collection.on("batchInsert", (function(_this) {
    return function(data) {
      var entries_count, percent_loaded, total_entries_count;
      total_entries_count = data.total_entries_count;
      entries_count = collection.size();
      percent_loaded = entries_count > 0 ? Math.round((entries_count / total_entries_count) * 100) : total_entries_count === 0 ? 100 : 0;
      view.moveProgressBar(percent_loaded);
      draw(percent_loaded / 100);
      return Dataclips.proxy.set({
        total_entries_count: total_entries_count,
        entries_count: entries_count,
        percent_loaded: percent_loaded,
        batch: data.records
      });
    };
  })(this));
  collection.fetchInBatches(this.config.params);
  return view.render();
};
