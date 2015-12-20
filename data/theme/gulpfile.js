var gulp        = require("gulp");
var sass        = require("gulp-sass");
var filter      = require('gulp-filter');

gulp.task('default', function () {
    return gulp.src('sass/*.scss')
        .pipe(sass({
            outputStyle: 'compressed',
            precision: 5,
            onError: function (err) {
                notify().write(err);
            }
        }))
        .pipe(gulp.dest('.'))
});
