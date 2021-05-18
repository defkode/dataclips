import "whatwg-fetch";
import Promise from "promise-polyfill";

import downloadCSV from "./download-csv";
import downloadXLSX from "./download-xlsx";

// To add to window
if (!window.Promise) {
  window.Promise = Promise;
}

class Insight {
  constructor(config) {
    let schema = Object.assign({}, config.schema);
    // dom_id
    const container = document.getElementById(config.dom_id);

    if (container) {
    } else {
      throw `element: ${config.dom_id} not found`;
    }

    // if (Object.keys(customFormatters).length) {
    //   Object.keys(config.schema).forEach((key) => {
    //     const formatter = config.schema[key]["formatter"];
    //     if (formatter) {
    //       if (customFormatters.formatters[formatter]) {
    //         schema[key]["formatter"] = customFormatters.formatters[formatter];
    //       } else {
    //         delete schema[key]["formatter"];
    //       }
    //     }
    //   });
    // }
    //
    // const filters = {};
    //
    // if (Object.keys(customOptions).length) {
    //   this.default_filter = customOptions.default_filter;
    //   this.rowActions = customOptions.rowActions;
    //
    //   if (customOptions.filters) {
    //     Object.keys(customOptions.filters).forEach((filterName) => {
    //       filters[filterName] = {};
    //       Object.keys(customOptions.filters[filterName]).forEach((key) => {
    //         filters[filterName][key] = {
    //           value: customOptions.filters[filterName][key],
    //         };
    //       });
    //     });
    //   }
    // }

    this.schema = schema;
    this.identifier = config.identifier;
    this.per_page = config.per_page;
    this.url = config.url;
    this.name = config.name;
    this.time_zone = config.time_zone;
    this.filters = filters;
    this.disable_seconds = config.disable_seconds;
    this.selectable = config.selectable;

    if (config.limit) {
      this.limit = config.limit;
    } else {
      const availableHeight = window.innerHeight - this.container.offsetTop;
      this.limit = Math.max(parseInt(availableHeight / 30) - 2, 20);
    }
  }

  // init(fn) {
  //   const {
  //     container,
  //     name,
  //     schema,
  //     identifier,
  //     per_page,
  //     limit,
  //     time_zone,
  //     url,
  //     fetchDataInBatches,
  //     filters,
  //     default_filter,
  //     rowActions,
  //     fetch,
  //     disable_seconds,
  //     selectable,
  //   } = this;
  //
  //   const reactable = Reactable.init({
  //     container: container,
  //     schema: schema,
  //     identifier: identifier,
  //     limit: limit,
  //     searchPresets: filters,
  //     actions: rowActions,
  //     displayTimeZone: time_zone,
  //     defaultSearchPreset: default_filter,
  //     itemsChange: (items) => {
  //       this.onChange(items);
  //     },
  //     disableSeconds: disable_seconds,
  //     selectable: selectable,
  //     controls: {
  //       xlsx: {
  //         onClick: (e) => {
  //           e.stopPropagation();
  //
  //           const button = e.target;
  //           const suggestedFilename = `${name}.xlsx`;
  //
  //           const filename = prompt("filename", suggestedFilename);
  //           if (filename !== null) {
  //             button.disabled = true;
  //             const data = reactable.getFilteredData();
  //             downloadXLSX(data, schema, filename).then(() => {
  //               button.disabled = false;
  //             });
  //           }
  //         },
  //         className: "r-icon-file-excel",
  //         key: "xlsx",
  //         label: "XLSX",
  //       },
  //       csv: {
  //         onClick: (e) => {
  //           e.stopPropagation();
  //
  //           const button = e.target;
  //           const suggestedFilename = `${name}.csv`;
  //
  //           const filename = prompt("filename", suggestedFilename);
  //
  //           if (filename !== null) {
  //             button.disabled = true;
  //             const data = reactable.getFilteredData();
  //             downloadCSV(data, schema, filename).then(() => {
  //               button.disabled = false;
  //             });
  //           }
  //         },
  //         className: "r-icon-doc-text",
  //         key: "csv",
  //         label: "CSV",
  //       },
  //       refresh: {
  //         onClick: (e) => {
  //           e.stopPropagation();
  //           reactable.clearData();
  //           fetch.apply(this);
  //         },
  //         className: "r-icon-arrows-cw",
  //         key: "refresh",
  //         label: "Refresh",
  //       },
  //     },
  //   });
  //
  //   reactable.render();
  //
  //   this.reactable = reactable;
  //
  //   if (default_filter) {
  //     reactable.applySearchPreset(default_filter);
  //   }
  //
  //   this.fetch();
  //   fn(this);
  }

  onChange() {} // implement me

  refresh() {
    this.reactable.clearData();
    this.fetch();
  }

  getSelected() {
    return this.reactable.getSelectedData();
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
}

export function insight(config, formatters, options) {
  const insight = new Insight(config);
  // insight.setFormatters(formatters);
  // insight.setOptions(options);
  insight.init();
}
