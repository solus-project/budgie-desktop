PKG_CHECK_MODULES(ICON_TASKLIST_PLUGIN,
    libwnck-3.0 >= 3.14.0,
    [have_wnck=yes], [have_wnck=no]
)

AM_CONDITIONAL(ENABLE_ICON_TASKLIST_PLUGIN, test x$have_wnck = xyes)
AC_CONFIG_FILES([panel/applets/icon-tasklist/Makefile])
