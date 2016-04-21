window.Dataclips = {
  Formatters: {
    text: function(row, cell, value, columnDef, context) {
      return value;
    },
    integer: function(row, cell, value, columnDef, context) {
      return value;
    },
    float: function(row, cell, value, columnDef, context) {
      return value;
    },
    decimal: function(row, cell, value, columnDef, context) {
      return value;
    },
    date: function(row, cell, value, columnDef, context) {
      return value != null ? value.format('L') : void 0;
    },
    time: function(row, cell, value, columnDef, context) {
      return value != null ? value.format('h:mm:ss') : void 0;
    },
    datetime: function(row, cell, value, columnDef, context) {
      return value != null ? value.format('L HH:mm:ss') : void 0;
    },
    binary: function(row, cell, value, columnDef, context) {
      return value;
    },
    boolean: function(row, cell, value, columnDef, context) {
      if (value === true) {
        return "&#9679";
      } else {
        return "&#9675;";
      }
    },
    email: function(row, cell, value, columnDef, context) {
      return "<a href='mailto:" + value + "'>" + value + "</a>";
    },
    price: function(row, cell, value, columnDef, context) {
      return value.toFixed(2);
    }
  },
  run: function() {
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
    collection = new Dataclips.Records;
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
  }
};


Dataclips.Record = Backbone.Model.extend({
  parse: function(options) {
    var attributes = _.reduce(options, function(memo, value, key) {

      v = switch (Dataclips.config.schema[key].type) {
          case "datetime":
          case "time":
          case "date":
            if (value != null) {
              return moment(value);
            }
            break;
          default:
            return value;
        }

      memo[key] = v;
      return memo;
    }, {});
  }
});

Dataclips.Records = Backbone.Collection.extend({
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
      data: defaultParams,
      success: function(collection, data) {
        collection.trigger("batchInsert", data);
        fetchNextPage(collection, data.page, data.total_pages);
      },
      error: function(collection, response) {
        alert(response.responseText);
      }
    });
  },
  parse: function(data) {
    return data.records;
  }
});