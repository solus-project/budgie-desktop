m4_define([upower_required_version], [0.9.20])

PKG_CHECK_MODULES(STATUS_PLUGIN,
     upower-glib >= upower_required_version,
    [have_upower=yes], [have_upower=no]
)

AM_CONDITIONAL(ENABLE_STATUS_PLUGIN, test x$have_upower = xyes)
AC_CONFIG_FILES([panel/applets/status/Makefile])
