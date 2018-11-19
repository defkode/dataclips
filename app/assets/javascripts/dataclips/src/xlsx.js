// ExcelBuilder
ExcelBuilder  = require("excel-builder-webpack");

module.exports = function() {
  var data, date_formatter, datetime_formatter, entries_count, keys, sheet, stylesheet, time_formatter, time_without_seconds_formatter, workbook;
  workbook = ExcelBuilder.Builder.createWorkbook();
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
  return ExcelBuilder.Builder.createFile(workbook, {
    type: "blob"
  });
};
