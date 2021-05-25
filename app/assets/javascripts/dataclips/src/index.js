import "whatwg-fetch";
import Promise from "promise-polyfill";

import downloadCSV from "./download-csv";
import downloadXLSX from "./download-xlsx";
import fetchDataInBatches from "./fetch-in-batches";

// To add to window
if (!window.Promise) {
  window.Promise = Promise;
}

class Insight {
  constructor(domId, schema, url, formatters, displayOptions, filters) {
    // dom_id
    const container = document.getElementById(domId);

    // UI: used in suggestedFilename
    const name = displayOptions.name;

    // UI: used for time formatting (default: browser's time_zone)
    const time_zone = displayOptions.time_zone;

    // used for remembering configuration between page reloads (i.e: visible columns) - saved in localStorage
    const cache_id = displayOptions.cache_id;

    // UI: limit - how many rows should be displayed?
    // TODO: autoscaling for fullpage view
    const limit = displayOptions.limit || 20;

    // UI: hide seconds - used in time formatters
    const disable_seconds = displayOptions.disable_seconds;

    if (Object.keys(formatters).length) {
      Object.keys(schema).forEach((key) => {
        const formatter = schema[key]["formatter"];
        if (formatter) {
          if (formatters.formatters[formatter]) {
            schema[key]["formatter"] = formatters.formatters[formatter];
          } else {
            delete schema[key]["formatter"];
          }
        }
      });
    }

    let searchPresets = {};

    if (Object.keys(filters).length) {
      // this.default_filter = customOptions.default_filter;

      Object.keys(filters).forEach((filterName) => {
        searchPresets[filterName] = {};
        Object.keys(filters[filterName]).forEach((key) => {
          searchPresets[filterName][key] = {
            value: filters[filterName][key],
          };
        });
      });
    }

    this.reactable = Reactable.init({
      container: container,
      schema: schema,
      identifier: cache_id,
      searchPresets: searchPresets,
      limit: limit,
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
            // fetch.apply(this);
          },
          className: "r-icon-arrows-cw",
          key: "refresh",
          label: "Refresh",
        },
      },
    });

    this.reactable.render();

    this.schema = schema;

    this.url = url;
  }

  fetch() {
    const { schema, reactable, url } = this;

    const processBatch = (result) => {
      const { data, currentPage, total_count, total_pages } = result;

      if (currentPage < total_pages) {
        fetchDataInBatches(currentPage + 1, url, schema).then(processBatch);
      }
      reactable.addData(result.data, total_count);
    };

    fetchDataInBatches(1, url, schema).then(processBatch);
  }
}

export function insight(
  dom_id,
  schema,
  fetchOptions,
  formatters,
  displayOptions,
  filters
) {
  return new Insight(
    dom_id,
    schema,
    fetchOptions,
    formatters,
    displayOptions,
    filters
  );
}
