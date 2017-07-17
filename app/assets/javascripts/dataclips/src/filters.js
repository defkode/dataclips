module.exports = {
  textFilter: function(item, attr, query) {
    var value;
    if (!query) {
      return true;
    }
    if (_.isEmpty(query.trim())) {
      return true;
    }
    value = item[attr];
    if (value == null) {
      return false;
    }
    return _.any(query.split(" OR "), function(keyword) {
      return value.toLowerCase().indexOf(keyword.toLowerCase()) !== -1;
    });
  },
  booleanFilter: function(item, attr, selector) {
    if (selector === void 0) {
      return true;
    }
    return selector === item[attr];
  },
  numericFilter: function(item, attr, range) {
    var gte, lte, value;
    value = item[attr];
    if (value === void 0) {
      return true;
    }
    if ((range.from != null) || (range.to != null)) {
      gte = function(from) {
        if (from === void 0) {
          return true;
        }
        return value >= from;
      };
      lte = function(to) {
        if (to === void 0) {
          return true;
        }
        return value <= to;
      };
      return gte(range.from) && lte(range.to);
    } else {
      return true;
    }
  },
  exactMatcher: function(item, attr, query) {
    if (!query) {
      return true;
    }
    if (_.isEmpty(query.trim())) {
      return true;
    }
    return item[attr] === query;
  }
}
