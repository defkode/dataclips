module.exports = {
  entry: './app/assets/javascripts/dataclips/src/main.js',

  module: {
    loaders: [
      { test: /\.coffee$/, loader: "coffee-loader" }
    ]
  },
  resolve: {
    extensions: [".coffee", ".js"]
  },
  output: {
    filename: 'bundle.js'
  }
}
