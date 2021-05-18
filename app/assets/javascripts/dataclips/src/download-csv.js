import { saveAs } from "file-saver";

const downloadCSV = (data, schema, filename) => {
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
};

export default downloadCSV;
