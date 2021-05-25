const fetchDataInBatches = (page = 1, url, schema) => {
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
};

export default fetchDataInBatches;
