Dataclips.run = ->
  bg = $('#progress').get(0)
  ctx = bg.getContext('2d')
  imd = null;
  circ = Math.PI * 2
  quart = Math.PI / 2

  ctx.beginPath()
  ctx.strokeStyle = '#6F5498'
  ctx.closePath()
  ctx.fill()
  ctx.lineWidth = 10.0

  imd = ctx.getImageData(0, 0, 240, 240)

  draw = (current) ->
    ctx.putImageData(imd, 0, 0)
    ctx.beginPath()
    ctx.arc(120, 120, 70, -(quart), ((circ) * current) - quart, false)
    ctx.stroke()

  collection = new Dataclips.Records

  collection.url = @config.url

  view = new Dataclips.View(collection: collection)

  collection.on "reset", =>
    Dataclips.proxy.set
      total_entries_count: 0
      entries: []
      grid_entries: []
      entries_count: 0
      grid_entries_count: 0
      percent_loaded: 0

  collection.on "batchInsert", (data) =>
    total_entries_count = data.total_entries_count
    entries_count = collection.size()

    percent_loaded = if entries_count > 0
      Math.round((entries_count / total_entries_count) * 100)
    else
      if total_entries_count is 0
        100
      else
        0

    view.moveProgressBar(percent_loaded)
    draw(percent_loaded / 100)

    Dataclips.proxy.set
      total_entries_count: total_entries_count
      entries_count:       entries_count
      percent_loaded:      percent_loaded
      entries:             collection.toJSON()
      grid_entries:        collection.toJSON()
      batch:               data.records

  collection.fetchInBatches(@config.params)
  view.render()
