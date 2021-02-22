import { saveAs } from "file-saver";
import "whatwg-fetch";
import Promise from "promise-polyfill";

ExcelBuilder = require("excel-builder-webpack");

const { Workbook, Builder } = ExcelBuilder;

// To add to window
if (!window.Promise) {
  window.Promise = Promise;
}

export default class Dataclips {
  constructor(config, customFormatters, customOptions) {
    let schema = Object.assign({}, config.schema);

    if (Object.keys(customFormatters).length) {
      Object.keys(config.schema).forEach((key) => {
        const formatter = config.schema[key]["formatter"];
        if (formatter) {
          if (customFormatters.formatters[formatter]) {
            schema[key]["formatter"] = customFormatters.formatters[formatter];
          } else {
            delete schema[key]["formatter"];
          }
        }
      });
    }

    const filters = {};

    if (Object.keys(customOptions).length) {
      this.default_filter = customOptions.default_filter;
      this.rowActions = customOptions.rowActions;

      if (customOptions.filters) {
        Object.keys(customOptions.filters).forEach((filterName) => {
          filters[filterName] = {};
          Object.keys(customOptions.filters[filterName]).forEach((key) => {
            filters[filterName][key] = {
              value: customOptions.filters[filterName][key],
            };
          });
        });
      }
    }

    this.schema = schema;
    this.container = document.getElementById(config.dom_id);
    this.identifier = config.identifier;
    this.per_page = config.per_page;
    this.url = config.url;
    this.name = config.name;
    this.time_zone = config.time_zone;
    this.filters = filters;

    if (config.limit) {
      this.limit = config.limit;
    } else {
      const availableHeight = window.innerHeight - this.container.offsetTop;
      this.limit = Math.max(parseInt(availableHeight / 30) - 2, 20);
    }
  }

  onChange() {} // implement me

  refresh() {
    this.reactable.clearData();
    this.fetch();
  }

  fetch() {
    const { url, schema, reactable, fetchDataInBatches } = this;
    const processBatch = (result) => {
      const { data, currentPage, total_count, total_pages } = result;

      if (currentPage < total_pages) {
        fetchDataInBatches(currentPage + 1, url, schema).then(processBatch);
      }
      reactable.addData(result.data, total_count);
    };

    fetchDataInBatches(1, url, schema).then(processBatch);
  }

  fetchDataInBatches(page = 1, url, schema) {
    const ISO8601 = /^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(\.\d+)?(([+-]\d\d:\d\d)|Z)?$/i;

    return fetch(url + "?page=" + page)
      .then(function (response) {
        return response.json();
      })
      .then(function (data) {
        if (data.length) {
          const records = data.map(function (i) {
            const parsedRecord = JSON.parse(i.record);
            let record = {};

            Object.entries(schema).forEach(([schemaKey, options]) => {
              const recordValue = parsedRecord[schemaKey];
              if (recordValue !== undefined) {
                if (options.type === "datetime" && recordValue !== null) {
                  if (ISO8601.test(recordValue)) {
                    const matches = recordValue.match(ISO8601);
                    const tz = matches[2];
                    if (tz) {
                      record[schemaKey] = recordValue;
                    } else {
                      // console.warn(`Dataclips: attribute '${schemaKey}' has no TZ information, assuming UTC`)
                      record[schemaKey] = `${recordValue}Z`; // UTC
                    }
                  } else {
                    throw new TypeError(
                      `Dataclips: ensure attribute '${schemaKey}' is valid ISO8601.`
                    );
                  }
                } else {
                  record[schemaKey] = recordValue;
                }
              } else {
                throw new TypeError(
                  `Dataclips: attribute '${schemaKey}' is undefined. Please verify schema.`
                );
              }
            });
            return record;
          });

          return {
            data: records,
            currentPage: data[0].page,
            total_count: data[0].total_count,
            total_pages: data[0].total_pages,
          };
        } else {
          return {
            data: [],
            currentPage: page,
            total_count: data.length,
            total_pages: page,
          };
        }
      });
  }

  downloadXLSX(data, schema, filename) {
    const workbook = Builder.createWorkbook();

    const xlsx_number_formats = {
      date_formatter: { id: 1, numFmtId: 14 },
      time_formatter: { id: 2, numFmtId: 21 },
      datetime_formatter: { id: 3, numFmtId: 22 },
      duration_formatter: { id: 4, numFmtId: 46 },
    };

    const stylesheet = workbook.getStyleSheet();
    stylesheet.fills = [{}, {}]; // reset weirdo default styles

    Object.entries(xlsx_number_formats).forEach(([key, format]) => {
      stylesheet.masterCellFormats.push(format);
    });

    const sheet = workbook.createWorksheet();

    const headers = Object.values(schema).map(function (value) {
      return value.label;
    });

    const rows = [];

    rows.push(headers);

    const minMs = 60 * 1000;
    const dayMs = 60 * 60 * 24 * 1000;

    data.forEach((item) => {
      const row = Object.entries(item).map(([key, value]) => {
        if (value !== null) {
          const type = schema[key].type;

          switch (type) {
            case "boolean":
              return {
                value: +value,
              };
            case "date":
              return {
                value: 25569 + Date.parse(value) / dayMs,
                metadata: { style: xlsx_number_formats.date_formatter.id },
              };
            case "time":
              return {
                value: value.as("day"),
                metadata: { style: xlsx_number_formats.time_formatter.id },
              };
            case "datetime":
              return {
                value: 25569 + (value.ts + value.offset * minMs) / dayMs,
                metadata: { style: xlsx_number_formats.datetime_formatter.id },
              };
            case "duration":
              return {
                value: value.as("day"),
                metadata: { style: xlsx_number_formats.duration_formatter.id },
              };
            default:
              return value;
          }
        } else {
          return null;
        }
      });

      rows.push(row);
    });

    sheet.setData(rows);
    workbook.addWorksheet(sheet);
    return new Promise(function (resolve, reject) {
      Builder.createFile(workbook, { type: "blob" }).then((blobData) => {
        const blob = new Blob([blobData], { type: "application/octet-stream" });
        saveAs(blob, filename);
        resolve();
      });
    });
  }

  downloadCSV(data, schema, filename) {
    if (data === null || !data.length) {
      return null;
    }

    const decimalSeparator = new Intl.NumberFormat()
      .formatToParts(1.1)
      .find((part) => part.type === "decimal").value;
    const columnDelimiter = decimalSeparator === "." ? "," : ";";

    let lines = [];

    const headerRow = Object.values(schema)
      .map(function (value) {
        return `"${value.label}"`;
      })
      .join(columnDelimiter);

    lines.push(headerRow);

    data.forEach(function (item) {
      const row = Object.entries(item)
        .map(([key, value]) => {
          if (value !== null) {
            const type = schema[key].type;

            switch (type) {
              case "number":
                return new Intl.NumberFormat().format(value);
              case "date":
                return value;
              case "datetime":
                return value.toFormat("yyyy-MM-dd HH:mm:ss");
              case "time":
              case "duration":
                return value.toFormat("hh:mm:ss");
              case "boolean":
                return value.toString().toUpperCase();
              default:
                return value;
            }
          } else {
            return null;
          }
        })
        .map(function (fieldValue) {
          if (fieldValue !== null) {
            return `"${fieldValue}"`;
          } else {
            return null;
          }
        })
        .join(columnDelimiter);

      lines.push(row);
    });

    const result = lines.join("\n");

    return new Promise(function (resolve, reject) {
      var blob = new Blob([result], { type: "text/csv;charset=utf-8" });
      saveAs(blob, filename);
      resolve();
    });
  }

  init(fn) {
    const {
      container,
      name,
      schema,
      identifier,
      per_page,
      limit,
      time_zone,
      url,
      fetchDataInBatches,
      downloadXLSX,
      downloadCSV,
      filters,
      default_filter,
      rowActions,
      fetch,
      disable_seconds,
    } = this;

    const reactable = Reactable.init({
      container: container,
      schema: schema,
      identifier: identifier,
      limit: limit,
      searchPresets: filters,
      actions: rowActions,
      displayTimeZone: time_zone,
      defaultSearchPreset: default_filter,
      itemsChange: (items) => {
        this.onChange(items);
      },
      disableSeconds: disable_seconds,
      controls: {
        xlsx: {
          onClick: (e) => {
            e.stopPropagation();

            const button = e.target;
            const suggestedFilename = `${name}.xlsx`;

            const filename = prompt("filename", suggestedFilename);
            if (filename !== null) {
              button.disabled = true;
              const data = reactable.getFilteredData();
              downloadXLSX(data, schema, filename).then(() => {
                button.disabled = false;
              });
            }
          },
          className: "r-icon-file-excel",
          key: "xlsx",
          label: "XLSX",
        },
        csv: {
          onClick: (e) => {
            e.stopPropagation();

            const button = e.target;
            const suggestedFilename = `${name}.csv`;

            const filename = prompt("filename", suggestedFilename);

            if (filename !== null) {
              button.disabled = true;
              const data = reactable.getFilteredData();
              downloadCSV(data, schema, filename).then(() => {
                button.disabled = false;
              });
            }
          },
          className: "r-icon-doc-text",
          key: "csv",
          label: "CSV",
        },
        refresh: {
          onClick: (e) => {
            e.stopPropagation();
            reactable.clearData();
            fetch.apply(this);
          },
          className: "r-icon-arrows-cw",
          key: "refresh",
          label: "Refresh",
        },
      },
    });

    reactable.render();

    this.reactable = reactable;

    if (default_filter) {
      reactable.applySearchPreset(default_filter);
    }

    this.fetch();
    fn(this);
  }
}
