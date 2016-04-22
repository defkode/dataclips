module.exports = {
  config: {},
  Formatters: {
    text: function(row, cell, value, columnDef, context) {
      return value;
    },
    integer: function(row, cell, value, columnDef, context) {
      return value;
    },
    float: function(row, cell, value, columnDef, context) {
      return value;
    },
    decimal: function(row, cell, value, columnDef, context) {
      return value;
    },
    date: function(row, cell, value, columnDef, context) {
      return value != null ? value.format('L') : void 0;
    },
    time: function(row, cell, value, columnDef, context) {
      return value != null ? value.format('h:mm:ss') : void 0;
    },
    datetime: function(row, cell, value, columnDef, context) {
      return value != null ? value.format('L HH:mm:ss') : void 0;
    },
    binary: function(row, cell, value, columnDef, context) {
      return value;
    },
    boolean: function(row, cell, value, columnDef, context) {
      if (value === true) {
        return "&#9679";
      } else {
        return "&#9675;";
      }
    },
    email: function(row, cell, value, columnDef, context) {
      return "<a href='mailto:" + value + "'>" + value + "</a>";
    },
    price: function(row, cell, value, columnDef, context) {
      return value.toFixed(2);
    }
  }
};




