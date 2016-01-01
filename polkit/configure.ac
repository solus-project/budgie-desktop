PKG_CHECK_MODULES(POLKIT_DIALOG,
    [
        polkit-gobject-1 >= polkit_required_version,
        polkit-agent-1 >= polkit_required_version,
        gtk+-3.0 >= gtk_required_version
    ],
    [have_polkit=yes], [have_polkit=no]
)

AM_CONDITIONAL(ENABLE_POLKIT_DIALOG, test x$have_polkit = xyes)
AC_CONFIG_FILES([polkit/Makefile])
