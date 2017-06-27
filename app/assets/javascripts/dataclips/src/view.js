require('../vendor/slickgrid/lib/jquery.event.drag-2.2');
require('../vendor/slickgrid/slick.core');
require('../vendor/slickgrid/slick.grid');
require('../vendor/slickgrid/slick.dataview');
require('../vendor/slickgrid/plugins/slick.autotooltips');
require('../vendor/slickgrid/plugins/slick.rowselectionmodel');

require("bootstrap");

var Workbook = require('excel-builder/src/Excel/Workbook');
var JSZip = require('jszip');

var downloader = require("downloadjs");

var moment = require("moment");

require("moment/locale/de");

module.exports = Backbone.View.extend({
  el: "body",
  events: {
    "click a.fullscreen": function() {
      this.requestFullScreen(document.body);
      return false;
    },
    "click a.reload": function() {
      this.reload();
      return false;
    },
    "click a.download": function(e) {
      if (Modernizr.adownload) {
        e.preventDefault();
        this.modal.modal('show');
        return $('#xlsx').tab('show');
      }
    },
    "click #download-dialog .btn.btn-primary": _.debounce(function(e) {
      var button, filename;
      button = $(e.target);
      if (this.$el.find(".tab-pane.active").attr("id") === "xlsx") {
        button.prop("disabled", true).blur().find("i").show();
        filename = $('#filename_xlsx').val() + '.xlsx';
        return setTimeout((function(_this) {
          return function() {
            return _this.buildXLSX().then(function(file) {
              _this.modal.modal('hide');
              button.prop("disabled", false).find("i").hide();
              return downloader(file, filename, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
            });
          };
        })(this), 100);
      } else {
        this.modal.modal('hide');
        return $("#download-dialog form").submit();
      }
    }),
    "input input[type=text]": _.debounce(function(event) {
      return this.filterArgs.set(event.target.name, $.trim(event.target.value));
    }),
    "change input.float[type=number]": _.debounce(function(event) {
      var value;
      value = parseFloat(event.target.value);
      if (_.isNaN(value)) {
        return this.filterArgs.unset(event.target.name);
      } else {
        return this.filterArgs.set(event.target.name, value);
      }
    }),
    "change input.integer[type=number]": _.debounce(function(event) {
      var value;
      value = parseInt(event.target.value);
      if (_.isNaN(value)) {
        return this.filterArgs.unset(event.target.name);
      } else {
        return this.filterArgs.set(event.target.name, value);
      }
    }),
    "change select.boolean": _.debounce(function(event) {
      var value;
      value = event.target.value;
      if (value === "") {
        return this.filterArgs.unset(event.target.name);
      } else {
        return this.filterArgs.set(event.target.name, value === "1");
      }
    }),
    "dp.change .input-group": _.debounce(function(event) {
      var attrName, value;
      value = event.date;
      attrName = $(event.target).attr("rel");
      if (value != null) {
        return this.filterArgs.set(attrName, value);
      } else {
        return this.filterArgs.unset(attrName);
      }
    }),
    "click button.reset": _.debounce(function(event) {
      var key;
      key = $(event.currentTarget).data("key");
      return this.resetFilter(key);
    })
  },
  resetFilter: function(key) {
    var type;
    type = Dataclips.config.schema[key]["type"];
    switch (type) {
      case "integer":
      case "float":
      case "decimal":
      case "date":
      case "datetime":
      case "time":
        this.$el.find("input[name=" + key + "_from]").val("");
        this.$el.find("input[name=" + key + "_to]").val("");
        this.filterArgs.unset(key + "_from");
        return this.filterArgs.unset(key + "_to");
      case "text":
        this.$el.find("input[name=" + key + "]").val("");
        return this.filterArgs.unset(key);
      case "boolean":
        this.$el.find("select[name=" + key + "]").val("");
        return this.filterArgs.unset(key);
      default:
        return this.filterArgs.unset(key);
    }
  },
  resetAllFilters: function() {
    return _.each(Dataclips.config.schema, (function(_this) {
      return function(options, key) {
        return _this.resetFilter(key);
      };
    })(this));
  },
  reload: function() {
    this.collection.reset();
    return this.collection.fetchInBatches();
  },
  requestFullScreen: function(element) {
    if (document.fullscreenEnabled || document.mozFullScreenEnabled || document.documentElement.webkitRequestFullScreen) {
      if (element.requestFullscreen) {
        return element.requestFullscreen();
      } else if (element.mozRequestFullScreen) {
        return element.mozRequestFullScreen();
      } else if (element.webkitRequestFullScreen) {
        return element.webkitRequestFullScreen();
      }
    }
  },
  render: function() {
    var booleanFilter, columns, dataView, exactMatcher, grid, numericFilter, options, textFilter, updateDataView;
    this.modal = $("#download-dialog").modal('hide');
    this.filterArgs = new Backbone.Model;
    this.listenTo(Dataclips.proxy, "change", _.debounce(function(model) {
      this.$el.find("span.total_entries_count").text(model.get("total_entries_count"));
      this.$el.find("span.entries_count").text(model.get("entries_count"));
      this.$el.find("span.percent_loaded").text(model.get("percent_loaded"));
      return this.$el.find("span.grid_entries_count").text(model.get("grid_entries_count"));
    }));
    window.addEventListener('message', (function(_this) {
      return function(e) {
        if (e.data.refresh === true) {
          _this.reload();
        }
        if (e.data.fullscreen === true) {
          _this.requestFullScreen(document.body);
        }
        if (e.data.filters) {
          _this.resetAllFilters();
          return _.each(e.data.filters, function(value, key) {
            var fromPicker, toPicker, type;
            if (Dataclips.config.schema[key] != null) {
              type = Dataclips.config.schema[key]["type"];
              switch (type) {
                case "boolean":
                  if (value != null) {
                    $("[name='" + key + "']").val(value === true ? "1" : "0");
                    return _this.filterArgs.set(key, value);
                  }
                  break;
                case "text":
                  if (value != null) {
                    $("[name='" + key + "']").val(value);
                    return _this.filterArgs.set(key, value);
                  }
                  break;
                case "float":
                case "integer":
                case "decimal":
                  if (value.from != null) {
                    $("[name='" + key + "_from']").val(value.from);
                    _this.filterArgs.set(key + "_from", value.from);
                  }
                  if (value.to != null) {
                    $("[name='" + key + "_to']").val(value.to);
                    return _this.filterArgs.set(key + "_to", value.from);
                  }
                  break;
                case "date":
                case "datetime":
                case "time":
                  if (value.from != null) {
                    fromPicker = $("[rel='" + key + "_from']");
                    fromPicker.data('DateTimePicker').date(moment(value.from));
                    _this.filterArgs.set(key + "_from", moment(value.from).toDate());
                  }
                  if (value.to != null) {
                    toPicker = $("[rel='" + key + "_to']");
                    toPicker.data('DateTimePicker').date(moment(value.to));
                    return _this.filterArgs.set(key + "_to", moment(value.to).toDate());
                  }
              }
            }
          });
        }
      };
    })(this));
    options = {
      enableColumnReorder: false,
      forceFitColumns: true,
      enableTextSelectionOnCells: true
    };
    dataView = new Slick.Data.DataView();
    dataView.setFilterArgs(this.filterArgs.toJSON());
    this.listenTo(this.filterArgs, "change", _.debounce(function(model, data) {
      dataView.setFilterArgs(model.attributes);
      return dataView.refresh();
    }));
    columns = [];
    _.each(Dataclips.config.schema, function(options, attr) {
      var formatter;
      formatter = options.formatter != null ? options.formatter : options.type;
      if (options.grid === true) {
        return columns.push({
          focusable: true,
          field: attr,
          id: attr,
          name: Dataclips.config.headers[attr],
          selectable: false,
          sortable: options.sortable != null,
          cssClass: options.type,
          headerCssClass: options.type,
          formatter: Dataclips.Formatters[formatter],
          width: options.width
        });
      }
    });
    grid = new Slick.Grid("#grid", dataView, columns, options);
    grid.registerPlugin(new Slick.AutoTooltips({
      enableForHeaderCells: true
    }));
    $(window).resize(function() {
      return grid.resizeCanvas();
    });
    grid.onSort.subscribe(function(e, args) {
      var compareByColumn, sortcol;
      sortcol = args.sortCol.field;
      compareByColumn = function(a, b) {
        var x, y;
        x = a[sortcol] || "";
        y = b[sortcol] || "";
        if (x === y) {
          return 0;
        } else {
          if (x > y) {
            return 1;
          } else {
            return -1;
          }
        }
      };
      return dataView.sort(compareByColumn, args.sortAsc);
    });
    textFilter = function(item, attr, query) {
      var value;
      if (!query) {
        return true;
      }
      if (_.isEmpty(query.trim())) {
        return true;
      }
      value = item[attr];
      if (value == null) {
        return false;
      }
      return _.any(query.split(" OR "), function(keyword) {
        return value.toLowerCase().indexOf(keyword.toLowerCase()) !== -1;
      });
    };
    booleanFilter = function(item, attr, selector) {
      if (selector === void 0) {
        return true;
      }
      return selector === item[attr];
    };
    numericFilter = function(item, attr, range) {
      var gte, lte, value;
      value = item[attr];
      if (value === void 0) {
        return true;
      }
      if ((range.from != null) || (range.to != null)) {
        gte = function(from) {
          if (from === void 0) {
            return true;
          }
          return value >= from;
        };
        lte = function(to) {
          if (to === void 0) {
            return true;
          }
          return value <= to;
        };
        return gte(range.from) && lte(range.to);
      } else {
        return true;
      }
    };
    exactMatcher = function(item, attr, query) {
      if (!query) {
        return true;
      }
      if (_.isEmpty(query.trim())) {
        return true;
      }
      return item[attr] === query;
    };
    dataView.setFilter(function(item, args) {
      return _.all(Dataclips.config.schema, function(options, attr) {
        switch (options.type) {
          case "text":
            return textFilter(item, attr, args[attr]);
          case "integer":
          case "float":
          case "decimal":
          case "datetime":
          case "date":
            return numericFilter(item, attr, {
              from: args[attr + "_from"],
              to: args[attr + "_to"]
            });
          case "boolean":
            return booleanFilter(item, attr, args[attr]);
          default:
            return true;
        }
      });
    });
    dataView.onPagingInfoChanged.subscribe(function(e, args) {
      var j, ref, results;
      return Dataclips.proxy.set({
        grid_entries_count: args.totalRows,
        grid_entries: _.map((function() {
          results = [];
          for (var j = 0, ref = args.totalRows - 1; 0 <= ref ? j <= ref : j >= ref; 0 <= ref ? j++ : j--){ results.push(j); }
          return results;
        }).apply(this), function(id) {
          return _.omit(dataView.getItem(id), "id");
        })
      });
    });
    dataView.onRowCountChanged.subscribe(function(e, args) {
      grid.updateRowCount();
      return grid.render();
    });
    dataView.onRowsChanged.subscribe(function(e, args) {
      grid.invalidateRows(args.rows);
      return grid.render();
    });
    updateDataView = function(data) {
      dataView.beginUpdate();
      dataView.setItems(data);
      return dataView.endUpdate();
    };
    this.listenTo(this.collection, "reset batchInsert", function() {
      return updateDataView(this.collection.toJSON());
    });
    if (!Modernizr.input.list) {
      return $('input[list]').relevantDropdown({
        fadeOutSpeed: 0
      });
    }
  },
  buildXLSX: function() {
    var data, date_formatter, datetime_formatter, entries_count, keys, sheet, stylesheet, time_formatter, time_without_seconds_formatter, workbook;
    workbook = new Workbook();
    stylesheet = workbook.getStyleSheet();
    stylesheet.fills = [{}, {}];
    sheet = workbook.createWorksheet();
    date_formatter = {
      id: 1,
      numFmtId: 14
    };
    time_without_seconds_formatter = {
      id: 2,
      numFmtId: 20
    };
    time_formatter = {
      id: 3,
      numFmtId: 21
    };
    datetime_formatter = {
      id: 4,
      numFmtId: 22
    };
    stylesheet.masterCellFormats.push(date_formatter);
    stylesheet.masterCellFormats.push(time_without_seconds_formatter);
    stylesheet.masterCellFormats.push(time_formatter);
    stylesheet.masterCellFormats.push(datetime_formatter);
    keys = _.keys(Dataclips.config.schema);
    data = [];
    data.push(_.map(keys, function(k) {
      return Dataclips.config.headers[k];
    }));
    entries_count = Dataclips.proxy.get("grid_entries").length;
    _.each(Dataclips.proxy.get("grid_entries"), (function(_this) {
      return function(record, i) {
        var values;
        values = _.map(Dataclips.config.schema, function(options, k) {
          var _v, formatter, offset, style, type, v;
          type = options.type;
          formatter = options.formatter;
          v = record[k];
          switch (type) {
            case "boolean":
              return {
                value: +v
              };
            case "date":
              if (v) {
                offset = moment(v).tz(Dataclips.config.time_zone).utcOffset() * 60 * 1000;
                _v = 25569.0 + ((v + offset) / (60 * 60 * 24 * 1000));
                return {
                  value: _v,
                  metadata: {
                    style: date_formatter.id
                  }
                };
              } else {
                return null;
              }
              break;
            case "datetime":
              if (v) {
                style = (function() {
                  switch (formatter) {
                    case "time":
                      return time_formatter.id;
                    case "time_without_seconds":
                      return time_without_seconds_formatter.id;
                    default:
                      return datetime_formatter.id;
                  }
                })();
                offset = moment(v).tz(Dataclips.config.time_zone).utcOffset() * 60 * 1000;
                _v = 25569.0 + ((v + offset) / (60 * 60 * 24 * 1000));
                return {
                  value: (formatter === "time_without_seconds" ? _v % 1 : _v),
                  metadata: {
                    style: style
                  }
                };
              } else {
                return null;
              }
              break;
            case "time":
              if (v) {
                offset = moment(v).tz(Dataclips.config.time_zone).utcOffset() * 60 * 1000;
                _v = 25569.0 + ((v + offset) / (60 * 60 * 24 * 1000));
                return {
                  value: _v,
                  metadata: {
                    style: time_formatter.id
                  }
                };
              } else {
                return null;
              }
              break;
            default:
              return v;
          }
        });
        return data.push(values);
      };
    })(this));
    sheet.setData(data);
    workbook.addWorksheet(sheet);

    return this.createFile(workbook, {
      type: "blob"
    });
  },

createFile: function (workbook, options) {
        var zip = new JSZip();
        return workbook.generateFiles().then(function (files) {
            _.each(files, function (content, path) {
                path = path.substr(1);
                if(path.indexOf('.xml') !== -1 || path.indexOf('.rel') !== -1) {
                    zip.file(path, content, {base64: false});
                } else {
                    zip.file(path, content, {base64: true, binary: true});
                }
            });
            return zip.generate(_.defaults(options || {}, {
                type: "base64"
            }));
        });
    }

});
