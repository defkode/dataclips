const path = require('path');
const webpack = require('webpack');

module.exports = {
  entry: [path.resolve(__dirname, 'src', 'index.js')],
  output: {
    filename: 'dataclips-bundle.js',
    path: path.resolve(__dirname, './dist')
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        use: [
          {
            loader: 'babel-loader'
          },
        ]
      }
    ]
  }
};
