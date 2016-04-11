m4_define([accountsservice_version], [0.6.40])

PKG_CHECK_MODULES(USERINDICATOR_PLUGIN,
    [
     accountsservice >= accountsservice_version
    ],
    [have_user_indicator=yes], [have_user_indicator=no]
)
AM_CONDITIONAL(ENABLE_USERINDICATOR_PLUGIN, test x$have_user_indicator = xyes)
AC_CONFIG_FILES([panel/applets/user-indicator/Makefile])
