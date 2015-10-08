Dataclips.Formatters =
  text:      (row, cell, value, columnDef, context) -> value
  integer:   (row, cell, value, columnDef, context) -> value
  float:     (row, cell, value, columnDef, context) -> value
  decimal:   (row, cell, value, columnDef, context) -> value
  date:      (row, cell, value, columnDef, context) -> if value? then moment(value).format('L') else undefined
  time:      (row, cell, value, columnDef, context) -> if value? then moment(value).format('h:mm:ss') else undefined
  datetime:  (row, cell, value, columnDef, context) -> if value? then moment(value).format('L HH:mm:ss') else undefined
  binary:    (row, cell, value, columnDef, context) -> value
  boolean:   (row, cell, value, columnDef, context) ->
    if value is true then "&#9679" else "&#9675;"
  email:     (row, cell, value, columnDef, context) ->
    "<a href='mailto:#{value}'>#{value}</a>"
  price:     (row, cell, value, columnDef, context) ->
    value.toFixed(2)
