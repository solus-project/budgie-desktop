var gulp        = require("gulp");
var sass        = require("gulp-sass");
var filter      = require('gulp-filter');

function buildTheme(version)
{
    return gulp.src(version + '/sass/*.scss')
        .pipe(sass({
            outputStyle: 'compressed',
            precision: 5,
            onError: function (err) {
                notify().write(err);
            }
        }))
        .pipe(gulp.dest(version))
}

var themeVersions = ['3.18', '3.20'];
themeVersions.forEach(function(version) {
    gulp.task(version, function() {
        return buildTheme(version);
    });
});

gulp.task('default', themeVersions);
