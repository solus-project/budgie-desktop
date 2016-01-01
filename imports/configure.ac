PKG_CHECK_MODULES(NATRAY,
    [
    gtk+-3.0 >= gtk_required_version,
    gtk+-x11-3.0 >= gtk_required_version,
    x11
    ],
    [have_natray=yes], [have_natray=no]
)

AM_CONDITIONAL(ENABLE_NATRAY, test x$have_natray = xyes)
AC_CONFIG_FILES([imports/Makefile
                 imports/natray/Makefile])
