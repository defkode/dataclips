import downloadCSV from "./download-csv";
import downloadXLSX from "./download-xlsx";

export default (config, context) => {
  let controls = {};

  if (config.xlsx) {
    controls.xlsx = {
      onClick: (e) => {
        e.stopPropagation();

        const button = e.target;
        const suggestedFilename = `${context.name}.xlsx`;

        const filename = prompt("filename", suggestedFilename);
        if (filename !== null) {
          button.disabled = true;
          const data = context.reactable.getFilteredData();
          downloadXLSX(data, context.schema, filename).then(() => {
            button.disabled = false;
          });
        }
      },
      className: "r-icon-file-excel",
      key: "xlsx",
      label: "XLSX",
    };
  }

  if (config.csv) {
    controls.csv = {
      onClick: (e) => {
        debugger;
        e.stopPropagation();

        const button = e.target;
        const suggestedFilename = `${context.name}.csv`;

        const filename = prompt("filename", suggestedFilename);

        if (filename !== null) {
          button.disabled = true;
          const data = context.reactable.getFilteredData();
          downloadCSV(data, context.schema, filename).then(() => {
            button.disabled = false;
          });
        }
      },
      className: "r-icon-doc-text",
      key: "csv",
      label: "CSV",
    };
  }

  if (config.refresh) {
    controls.refresh = {
      onClick: (e) => {
        e.stopPropagation();
        context.reactable.clearData();
        context.fetch();
      },
      className: "r-icon-arrows-cw",
      key: "refresh",
      label: "Refresh",
    };
  }

  return controls;
};
