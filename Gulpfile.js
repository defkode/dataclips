var gulp, sourcemaps, browserify, coffeeify, sass, less, concat, source;

gulp       = require('gulp');
sourcemaps = require('gulp-sourcemaps');
browserify = require('browserify');
coffeeify  = require('coffeeify');
sass       = require("gulp-sass");
less       = require("gulp-less");
source     = require('vinyl-source-stream');
concat     = require('gulp-concat');

// gulp.task('default', ['compile-coffee']);

gulp.task('bundle-css', function() {
  gulp.src(['./node_modules/bootstrap/dist/css/bootstrap.css', './node_modules/eonasdan-bootstrap-datetimepicker/build/css/bootstrap-datetimepicker.css', './app/assets/stylesheets/dataclips/dataclips.css'])
      .pipe(concat('application.css'))
      .pipe(gulp.dest('./app/assets/stylesheets/dataclips'));
});

gulp.task('compile-sass', function() {
    gulp.src('./app/assets/stylesheets/dataclips/dataclips.sass')
    .pipe(sass())
    .pipe(gulp.dest('./app/assets/stylesheets/dataclips'));
});

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
