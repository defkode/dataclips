const path = require("path");
const webpack = require("webpack");

module.exports = {
  entry: [path.resolve(__dirname, "src", "index.js")],
  output: {
    path: path.resolve(__dirname, "dist"),
    filename: "dataclips-bundle.js",
    library: "Dataclips",
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        use: [
          {
            loader: "babel-loader",
          },
        ],
      },
    ],
  },
};
