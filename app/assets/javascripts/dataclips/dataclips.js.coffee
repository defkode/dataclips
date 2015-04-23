Dataclips.run = ->
  window.addEventListener 'message', (event) ->
    mainWindow = event.source


  bg = $('#progress').get(0)
  ctx = bg.getContext('2d')
  imd = null;
  circ = Math.PI * 2
  quart = Math.PI / 2

  ctx.beginPath()
  ctx.strokeStyle = '#999'
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

  collection.on "batchInsert", (data) ->
    total_entries = data.total_entries
    entries_count = collection.size()
    percent_loaded = if entries_count > 0 then Math.round((entries_count / total_entries) * 100) else 0

    view.moveProgressBar(percent_loaded)
    draw(percent_loaded / 100)

    window.parent.postMessage
      total_entries: total_entries
      entries_count: entries_count,
      percent_loaded: percent_loaded
    , "*"


  collection.fetchInBatches(@config.params)
  view.render()
