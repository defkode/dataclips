import { saveAs } from "file-saver";

ExcelBuilder = require("excel-builder-webpack");

const { Workbook, Builder } = ExcelBuilder;

const downloadXLSX = (data, schema, filename) => {
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
};

export default downloadXLSX;
