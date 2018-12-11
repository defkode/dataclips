const path = require('path');
const webpack = require('webpack');

module.exports = {
  mode:  'development',
  entry: [path.resolve(__dirname, 'src', 'index.js')],
  output: {
    filename: 'dataclips-bundle.js',
    path: path.resolve('./dist')
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
