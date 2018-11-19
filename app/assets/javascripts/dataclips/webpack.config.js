const path = require('path');
const webpack = require('webpack');

module.exports = {
  mode:  'development',
  entry: ['babel-polyfill', path.resolve(__dirname, 'src', 'index.js')],
  output: {
    filename: 'bundle.js',
    path: path.resolve('./dist')
  },
  resolve: {
    alias: {}
  },
  module: {
    rules: [
      {
        test: /\.coffee$/,
        use: [
          {
            loader: 'babel-loader'
          },
          {
            loader: 'coffee-loader'
          }
        ]
      }
    ]
  },
  plugins: [
    new webpack.ProvidePlugin({
      _: 'underscore',
      Backbone: 'backbone',
      moment: 'moment-timezone'
    })

  ]
};