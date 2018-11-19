moment = require("moment");
require("moment-timezone");

module.exports = Backbone.Model.extend({
  parse: function(options) {
    var attributes = {};
    var schema = Dataclips.config.schema;

    var key, value, hasProp = {}.hasOwnProperty;

    for (key in options) {
      if (!hasProp.call(options, key)) continue;
      value = options[key];
      var type = schema[key].type;
      if (type === "date" || type === "time" || type === "datetime") {
        if (value != null) {
          attributes[key] = parseInt(moment(value).format('x'));
        }
      } else if (type === "text") {
        var temp = document.createElement('div');
        temp.textContent = value;
        attributes[key] = temp.innerHTML;
      } else {
        attributes[key] = value;
      }
    }
    if(attributes.id === undefined) { attributes.id = this.cid; }
    return attributes
  }
});
