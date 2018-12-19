import { saveAs } from 'file-saver'
ExcelBuilder = require("excel-builder-webpack")

const { Workbook, Builder } = ExcelBuilder

export default class Dataclips {
  constructor(config) {
    let schema = Object.assign({}, config.schema)

    Object.keys(config.schema).forEach((key) => {
      const formatter = config.schema[key]['formatter']
      if (formatter) {
        if (window[formatter]) {
          schema[key]['formatter'] = window[formatter]
        } else {
          delete schema[key]['formatter']
        }
      }
    })
    this.schema    = schema
    this.container = document.getElementById(config.dom_id)
    this.per_page  = config.per_page
    this.url       = config.url
    this.name      = config.name
  }

  fetchData(url, reactable) {
    return fetch(url).then(function(response) {
      return response.json()
    }).then(function(data) {
      return data.map(function(i){
        return JSON.parse(i.record)
      })
    })
  }


  fetchDataInBatches(page = 1, url, reactable) {
    return fetch(url + '?page=' + page).then(function(response) {
      return response.json()
    }).then(function(data) {

      const records = data.map(function(i){
        return JSON.parse(i.record)
      })

      return {
        data:        records,
        currentPage: data[0].page,
        total_count: data[0].total_count,
        total_pages: parseInt(data[0].total_pages, 10)
      }
    })
  }

  downloadXLSX(data) {
    const { name, schema } = this
    const suggestedFilename = `${name}.xlsx`

    const workbook = Builder.createWorkbook()

    const date_formatter                 = {id: 1, numFmtId: 14}
    const time_without_seconds_formatter = {id: 2, numFmtId: 20}
    const time_formatter                 = {id: 3, numFmtId: 21}
    const datetime_formatter             = {id: 4, numFmtId: 22}
    const duration_formatter             = {id: 5, numFmtId: 46}

    const stylesheet = workbook.getStyleSheet()
    stylesheet.fills = [{}, {}]
    stylesheet.masterCellFormats.push(date_formatter)
    stylesheet.masterCellFormats.push(time_without_seconds_formatter)
    stylesheet.masterCellFormats.push(time_formatter)
    stylesheet.masterCellFormats.push(datetime_formatter)
    stylesheet.masterCellFormats.push(duration_formatter)



    const sheet = workbook.createWorksheet()

    const headers = Object.keys(schema)

    const rows = []

    rows.push(headers)

    data.forEach((item) => {
      const row = Object.entries(item).map(([key, value]) => {
        if (value) {
          const type = schema[key].type

          switch (type) {
            case 'boolean':
              return +value
            case 'datetime':
              const minMs = 60 * 1000
              const dayMs = (60 * 60 * 24 * 1000)

              const _value = 25569.0 + ((value.ts + (value.offset * minMs)) / dayMs)

              return {
                value: _value,
                metadata: {
                  style: datetime_formatter.id
                }
              }
            case 'duration':

              return {
                value: value.as('day'),
                metadata: {
                  style: duration_formatter.id
                }
              }
            default:
              return value
          }
        } else {
          return null
        }
      })

      rows.push(row)
    })

    console.log(rows)

    sheet.setData(rows)
    workbook.addWorksheet(sheet)

    Builder.createFile(workbook, {type: 'blob'}).then((blobData) => {
      const filename = prompt('filename', suggestedFilename) || suggestedFilename
      const blob = new Blob( [blobData], {type: "application/octet-stream"} )
      saveAs(blob, filename)
    })
  }

  //
  //
  // switch (type) {
  //         case "boolean":
  //           return {
  //             value: +v
  //           };
  //         case "date":
  //           if (v) {
  //             offset = moment(v).tz(Dataclips.config.time_zone).utcOffset() * 60 * 1000;
  //             _v = 25569.0 + ((v + offset) / (60 * 60 * 24 * 1000));
  //             return {
  //               value: _v,
  //               metadata: {
  //                 style: date_formatter.id
  //               }
  //             };
  //           } else {
  //             return null;
  //           }
  //           break;
  //         case "datetime":
  //           if (v) {
  //             style = (function() {
  //               switch (formatter) {
  //                 case "time":
  //                   return time_formatter.id;
  //                 case "time_without_seconds":
  //                   return time_without_seconds_formatter.id;
  //                 default:
  //                   return datetime_formatter.id;
  //               }
  //             })();
  //             offset = moment(v).tz(Dataclips.config.time_zone).utcOffset() * 60 * 1000;
  //             _v = 25569.0 + ((v + offset) / (60 * 60 * 24 * 1000));
  //             return {
  //               value: (formatter === "time_without_seconds" ? _v % 1 : _v),
  //               metadata: {
  //                 style: style
  //               }
  //             };
  //           } else {
  //             return null;
  //           }
  //           break;
  //         case "time":
  //           if (v) {
  //             offset = moment(v).tz(Dataclips.config.time_zone).utcOffset() * 60 * 1000;
  //             _v = 25569.0 + ((v + offset) / (60 * 60 * 24 * 1000));
  //             return {
  //               value: _v,
  //               metadata: {
  //                 style: time_formatter.id
  //               }
  //             };
  //           } else {
  //             return null;
  //           }
  //           break;
  //         default:
  //           return v;
  //       }
  //     });


  init() {
    const { container, schema, per_page, url, fetchData, fetchDataInBatches, downloadXLSX } = this

    const reactable = Reactable.init({
      container:   container,
      schema:      schema,
      limit:       parseInt(window.innerHeight / 30) - 2,
      controls: {
        csv: {
          onClick: (e) => {
            const data = reactable.getFilteredData()
            downloadXLSX.bind(this)(data)
          },
          className: '',
          key: 'xlsx',
          disabled: false,
          label: 'Download XLSX',
        }
      }
    })

    reactable.render()

    if (per_page) {
      const processBatch = (result) => {
        const { data, currentPage, total_count, total_pages} = result

        if (currentPage < total_pages) {
          fetchDataInBatches(currentPage + 1, url, reactable).then(processBatch)
        }
        reactable.addData(result.data)
      }

      fetchDataInBatches(1, url, reactable).then(processBatch)
    } else {
      fetchData(url, reactable).then(function(data){
        reactable.addData(data)
      })
    }
  }
}
