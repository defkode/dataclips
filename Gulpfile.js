var gulp, sourcemaps, browserify, coffeeify, source;

gulp = require('gulp');
sourcemaps = require('gulp-sourcemaps');
browserify = require('browserify');
coffeeify = require('coffeeify');
source = require('vinyl-source-stream');

gulp.task('default', ['compile-coffee']);

gulp.task('compile-coffee', function() {
  var stream = browserify('./app/assets/javascripts/dataclips/src/main.js',
    { debug: false /* enables source maps */,
      extensions: ['.js', '.coffee'] }
  )
  .transform('coffeeify')
   .bundle();

  stream.pipe(source('bundle.js'))
        .pipe(gulp.dest('./app/assets/javascripts/dataclips/dist'));
});