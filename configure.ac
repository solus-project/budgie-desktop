AC_INIT([Budgie Desktop], 8.1, [ikey@evolve-os.com], [budgie-desktop], [https://evolve-os.com/])
AM_INIT_AUTOMAKE([-Wno-portability no-dist-gzip dist-xz foreign subdir-objects])
AC_PROG_CC
AC_PROG_CC_STDC
LT_PREREQ(2.2)
AC_CONFIG_HEADERS([config.h])
AC_PREFIX_DEFAULT(/usr/local)
AM_SILENT_RULES([yes])
LT_INIT([disable-static])

GLIB_GSETTINGS

GETTEXT_PACKAGE=budgie-desktop
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, "$GETTEXT_PACKAGE",
                   [The prefix for our gettext translation domains.])

# Package requirements
PKG_CHECK_MODULES([GOBJECT], [gobject-2.0 >= 2.38.0])
PKG_CHECK_MODULES([GIO], [gio-2.0 >= 2.38.0])
PKG_CHECK_MODULES([GTK3], [gtk+-3.0 >= 3.10.0])

PULSE_MIN_VERS=2.0

MODULEDIR=${libdir}/budgie-desktop
AC_SUBST(MODULEDIR)
AC_DEFINE_UNQUOTED(MODULEDIR, "$MODULEDIR",
                   [Installation directory for Budgie plugins])

# Technically unused right now but might be used in the future
MODULE_DATA_DIR=${datadir}/budgie-desktop/plugins
AC_SUBST(MODULE_DATA_DIR)
AC_DEFINE_UNQUOTED(MODULE_DATA_DIR, "$MODULEDIR",
                   [Installation directory for Budgie plugin data])

PKG_CHECK_MODULES(GVC, libpulse >= $PULSE_MIN_VERS libpulse-mainloop-glib gobject-2.0)

AC_ARG_ENABLE(wm, AS_HELP_STRING([--enable-wm], [enable wm @<:@default=yes@:>@]),
             [], [enable_wm=yes])
AS_IF([test "x$enable_wm" = "xyes"],
       [AC_DEFINE([BUILD_WM], [1], [Building window manager])],
       [])
AM_CONDITIONAL([BUILD_WM], [test x$enable_wm = x"yes"])

if test "x$enable_wm" = "xyes"; then
    # Required for Window Manager component
    PKG_CHECK_MODULES([MUTTER], [libmutter >= 3.14.0])
fi

# Wnck required for budgie-panel
PKG_CHECK_MODULES([WNCK3], [libwnck-3.0 >= 3.4.7])

# Required for power-applet
PKG_CHECK_MODULES([UPOWER], [upower-glib >= 0.9.20])

# Required for menu in the panel
PKG_CHECK_MODULES([GMENU], [libgnome-menu-3.0 >= 3.10.1])

# Required for panel applets
PKG_CHECK_MODULES([LIBPEAS], [libpeas-gtk-1.0 >= 1.8.0])

# Because we target Linux.
PKG_CHECK_MODULES([GIO_UNIX], [gio-unix-2.0 >= 2.38.0])

AC_PATH_PROG(GLIB_COMPILE_RESOURCES, glib-compile-resources)

AC_CONFIG_MACRO_DIR([m4])

GOBJECT_INTROSPECTION_CHECK([1.38.0])

# For various Vala things.
PKG_CHECK_MODULES([GEE], [gee-0.8])

# Need Vala.
AM_PROG_VALAC([0.26], [], [AC_MSG_ERROR([valac is required to build Budgie Desktop])])

# Determine if upower is newer than we're supporting right now
PKG_CHECK_MODULES(UPOWER99, [upower-glib >= 0.9.99], [have_upower0999=yes], [have_upower0999=no])
if test "x$have_upower0999" = "xyes" ; then
    VALAFLAGS="$VALAFLAGS --define HAVE_UPOWER0999"
fi


# Check for GTK3.13+ (Le World Blow Up)
PKG_CHECK_MODULES(GTK313, [gtk+-3.0  >= 3.13], [have_gtk313=yes], [have_gtk313=no])
if test "x$have_gtk313" = "xyes" ; then
    VALAFLAGS="$VALAFLAGS --define HAVE_GTK313"
fi

# Check for glib >= 2.40 (GAppInfoMonitor introduction)
PKG_CHECK_MODULES(GLIB240, [gio-2.0  >= 2.40], [have_glib240=yes], [have_glib240=no])
if test "x$have_glib240" = "xyes" ; then
    VALAFLAGS="$VALAFLAGS --define HAVE_GLIB240"
fi

AC_SUBST(VALAFLAGS)

AC_CONFIG_FILES([Makefile
                data/Makefile
                data/budgie-desktop.desktop
                gvc/Makefile
                budgie-plugin/budgie-1.0.pc
                budgie-plugin/Makefile
                imports/Makefile
                imports/natray/Makefile
                panel/Makefile
                panel/applets/Makefile
                panel/applets/budgie-menu/Makefile
                panel/applets/clock/Makefile
                panel/applets/icontasklist/Makefile
                panel/applets/lock-keys/Makefile
                panel/applets/menubar/Makefile
                panel/applets/tasklist/Makefile
                panel/applets/status/Makefile
                panel/applets/workspaces/Makefile
                panel/applets/tray/Makefile
                panel/applets/notifications/Makefile
                rundialog/Makefile
                session/Makefile
                widgets/Makefile
                wm/Makefile])
AC_OUTPUT

AC_MSG_RESULT([
        budgie-desktop $VERSION
        ========

        prefix:                 ${prefix}
        libdir:                 ${libdir}
        sysconfdir:             ${sysconfdir}
        exec_prefix:            ${exec_prefix}
        bindir:                 ${bindir}
        datarootdir:            ${datarootdir}

        compiler:               ${CC}
        cflags:                 ${CFLAGS}
        ldflags:                ${LDFLAGS}

        wm:                     ${enable_wm}
])
