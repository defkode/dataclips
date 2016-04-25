moment = require("moment");

module.exports = Backbone.Model.extend({
  parse: function(options) {
    var attributes = _.reduce(options, function(memo, value, key) {
      var type = Dataclips.config.schema[key].type;
      if (type === "date" || type === "time" || type === "datetime") {
        if (value != null) {
          memo[key] = parseInt(moment(value).format('x'));
        }
      } else {
        memo[key] = value;
      }
    return memo;
    }, {});

    attributes.id = this.cid
    return attributes
  }
});