require.config({
  shim: {

  },
  paths: {
    backbone: "bower_components/backbone/backbone",
    jquery: "bower_components/jquery/dist/jquery"
  },
  packages: [
    {
      name: "excel-builder-js",
      main: "dist/excel-builder.dist.js"
    }
  ]
});