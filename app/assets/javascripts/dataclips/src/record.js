moment = require("moment");
require("moment-timezone");

module.exports = Backbone.Model.extend({
  parse: function(options) {
    var attributes = {};
    var schema = Dataclips.config.schema;

    for (key in options) {
      if (!Object.hasOwnProperty.call(options, key)) continue;
      if (schema[key] === undefined) continue;

      value = options[key];
      var type = schema[key].type;
      if (type === "date" || type === "time" || type === "datetime") {
        if (value != null) {
          attributes[key] = parseInt(moment(value).format('x'));
        }
      } else {
        attributes[key] = value;
      }
    }
    if(attributes.id === undefined) { attributes.id = this.cid; }
    return attributes
  }
});
