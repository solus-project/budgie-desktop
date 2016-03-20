m4_define([upower_required_version], [0.9.20])
m4_define([bt_required_version], [3.16.0])

PKG_CHECK_MODULES(STATUS_PLUGIN,
     upower-glib >= upower_required_version,
    [have_upower=yes], [have_upower=no]
)
PKG_CHECK_MODULES(BLUETOOTH,
     gnome-bluetooth >= bt_required_version,
     [have_bluetooth=no], [have_bluetooth=yes]
)

AM_CONDITIONAL(ENABLE_STATUS_PLUGIN, test x$have_upower = xyes)
AM_CONDITIONAL(ENABLE_BLUETOOTH, test x$have_bluetooth = xyes)
AC_CONFIG_FILES([panel/applets/status/Makefile])
