import "whatwg-fetch";
import Promise from "promise-polyfill";

import fetchDataInBatches from "./fetch-in-batches";
import controls from "./controls";

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
    const limit = displayOptions.limit || 25;

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
      Object.keys(filters).forEach((filterName) => {
        searchPresets[filterName] = {};
        Object.keys(filters[filterName]).forEach((key) => {
          searchPresets[filterName][key] = {
            value: filters[filterName][key],
          };
        });
      });
    }

    controls.bind(this);

    this.reactable = Reactable.init({
      container: container,
      schema: schema,
      identifier: cache_id,
      searchPresets: searchPresets,
      defaultSearchPreset: displayOptions.default_filter,
      limit: limit,
      controls: controls({ csv: true, xlsx: true, refresh: true }, this),
    });

    this.schema = schema;
    this.url = url;
    this.name = name;

    this.reactable.render();
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
