import { saveAs } from 'file-saver'
import 'whatwg-fetch'
import Promise from 'promise-polyfill'

ExcelBuilder = require("excel-builder-webpack")

const { Workbook, Builder } = ExcelBuilder

// To add to window
if (!window.Promise) {
  window.Promise = Promise
}

export default class Dataclips {
  constructor(config, customFormatters) {
    let schema = Object.assign({}, config.schema)

    if (customFormatters) {
      Object.keys(config.schema).forEach((key) => {
        const formatter = config.schema[key]['formatter']
        if (formatter) {
          if (customFormatters[formatter]) {
            schema[key]['formatter'] = customFormatters[formatter]
          } else {
            delete schema[key]['formatter']
          }
        }
      })
    }

    this.schema     = schema
    this.container  = document.getElementById(config.dom_id)
    this.identifier = config.identifier
    this.per_page   = config.per_page
    this.url        = config.url
    this.name       = config.name
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


  fetchDataInBatches(page = 1, url, schema) {
    const ISO8601 = /^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(\.\d+)?(([+-]\d\d:\d\d)|Z)?$/i

    return fetch(url + '?page=' + page).then(function(response) {
      return response.json()
    }).then(function(data) {
      const records = data.map(function(i){
        const parsedRecord = JSON.parse(i.record)
        let record = {}

        Object.entries(schema).forEach(([schemaKey, options]) => {
          const recordValue = parsedRecord[schemaKey]
          if (recordValue !== undefined) {
            if (options.type === 'datetime' && recordValue !== null) {
              if (ISO8601.test(recordValue)) {
                const matches = recordValue.match(ISO8601)
                const tz      = matches[2]
                if (tz) {
                  record[schemaKey] = recordValue
                } else {
                  // console.warn(`Dataclips: attribute '${schemaKey}' has no TZ information, assuming UTC`)
                  record[schemaKey] = `${recordValue}Z` // UTC
                }
              } else {
                debugger
                throw new TypeError(`Dataclips: ensure attribute '${schemaKey}' is valid ISO8601.`)
              }
            } else {
              record[schemaKey] = recordValue
            }

          } else {
            throw new TypeError(`Dataclips: attribute '${schemaKey}' is undefined. Please verify schema.`)
          }
        })
        return record
      })

      return {
        data:        records,
        currentPage: data[0].page,
        total_count: data[0].total_count,
        total_pages: parseInt(data[0].total_pages, 10)
      }
    })
  }

  downloadXLSX(data, schema, filename) {
    const workbook = Builder.createWorkbook()

    const xlsx_number_formats = {
      datetime_formatter:  {id: 1, numFmtId: 22},
      duration_formatter:  {id: 2, numFmtId: 46}
    }

    const stylesheet = workbook.getStyleSheet()
    stylesheet.fills = [{}, {}] // reset weirdo default styles

    Object.entries(xlsx_number_formats).forEach(([key, format]) => {
      stylesheet.masterCellFormats.push(format)
    })

    const sheet = workbook.createWorksheet()

    const headers = Object.keys(schema)

    const rows = []

    rows.push(headers)

    data.forEach((item) => {
      const row = Object.entries(item).map(([key, value]) => {
        if (value !== null) {
          const type = schema[key].type

          switch (type) {
            case 'boolean':
              return {
                value: +value
              }
            case 'datetime':
              const minMs = 60 * 1000
              const dayMs = (60 * 60 * 24 * 1000)

              const _value = 25569.0 + ((value.ts + (value.offset * minMs)) / dayMs)

              return {
                value: _value,
                metadata: {style: xlsx_number_formats.datetime_formatter.id}
              }
            case 'duration':
            case 'time':
              return {
                value: value.as('day'),
                metadata: {style: xlsx_number_formats.duration_formatter.id}
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

    sheet.setData(rows)
    workbook.addWorksheet(sheet)
    return new Promise(function(resolve, reject) {

      Builder.createFile(workbook, {type: 'blob'}).then((blobData) => {
        const blob = new Blob( [blobData], {type: "application/octet-stream"} )
        saveAs(blob, filename)
        resolve()
      })
    })
  }

  init() {
    const { container, name, schema, identifier, per_page, url, fetchData, fetchDataInBatches, downloadXLSX } = this

    const reactable = Reactable.init({
      container:   container,
      schema:      schema,
      identifier:  identifier,
      limit:       parseInt(window.innerHeight / 30) - 2,
      controls: {
        xlsx: {
          onClick: (e) => {
            const button = e.target
            const suggestedFilename = `${name}.xlsx`

            const filename = prompt('filename', suggestedFilename)
            if (filename !== null) {
              button.disabled = true
              const data = reactable.getFilteredData()
              downloadXLSX(data, schema, filename).then(() => {
                button.disabled = false
              })
            }
          },
          className: 'btn',
          key: 'xlsx',
          label: 'Download XLSX',
        }
      }
    })

    reactable.render()

    if (per_page) {
      const processBatch = (result) => {
        const { data, currentPage, total_count, total_pages} = result

        if (currentPage < total_pages) {
          fetchDataInBatches(currentPage + 1, url, schema).then(processBatch)
        }
        reactable.addData(result.data, total_count)
      }

      fetchDataInBatches(1, url, schema).then(processBatch)
    } else {
      fetchData(url).then(function(data){
        reactable.addData(data)
      })
    }
  }
}
