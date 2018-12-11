Dataclips = {};

Dataclips.fetchData = function(url, table) {
  fetch(url).then(function(response) {
    return response.json()
  }).then(function(data) {
    console.log(data);
    var records = data.map(function(i){
      record = JSON.parse(i.record)
      return record;
    })
    table.addData(records);
  });
}

Dataclips.fetchInBatches = function(page = 1, url, table) {
  fetch(url + '?page=' + page).then(function(response) {
    return response.json()
  }).then(function(data) {
    var currentPage = data[0].page
    var total_count = data[0].total_count
    var total_pages = parseInt(data[0].total_pages, 10)

    var records = data.map(function(i){
      record = JSON.parse(i.record)
      return record;
    })
    table.addData(records);
    if (currentPage < total_pages) {
      Dataclips.fetchInBatches(currentPage + 1, url, table);
    }
  });
}
