AC_INIT([Arc Desktop], 1, [ikey@solus-project.com], [arc-desktop], [https://solus-project.com/])
AM_INIT_AUTOMAKE([-Wno-portability no-dist-gzip dist-xz foreign subdir-objects])
AC_PROG_CC
AC_PROG_CC_STDC
LT_PREREQ(2.2)
AC_CONFIG_HEADERS([config.h])
AC_PREFIX_DEFAULT(/usr/local)
AM_SILENT_RULES([yes])
LT_INIT([disable-static])

GLIB_GSETTINGS

GETTEXT_PACKAGE=arc-desktop
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, "$GETTEXT_PACKAGE",
                   [The prefix for our gettext translation domains.])

# Package requirements
PKG_CHECK_MODULES([GOBJECT], [gobject-2.0 >= 2.44.0])
PKG_CHECK_MODULES([GIO], [gio-2.0 >= 2.44.0])
PKG_CHECK_MODULES([GTK3], [gtk+-3.0 >= 3.16.0])
PKG_CHECK_MODULES([GIO_UNIX], [gio-unix-2.0 >= 2.44.0])
PKG_CHECK_MODULES([UUID], [uuid])
# Required for panel applets
PKG_CHECK_MODULES([LIBPEAS], [libpeas-gtk-1.0 >= 1.8.0])

# Required for menu in the panel
PKG_CHECK_MODULES([GMENU], [libgnome-menu-3.0 >= 3.10.1])

PULSE_MIN_VERS=2.0

MODULEDIR=${libdir}/arc-desktop
AC_SUBST(MODULEDIR)
AC_DEFINE_UNQUOTED(MODULEDIR, "$MODULEDIR",
                   [Installation directory for Arc plugins])

# Technically unused right now but might be used in the future
MODULE_DATA_DIR=${datadir}/arc-desktop/plugins
AC_SUBST(MODULE_DATA_DIR)
AC_DEFINE_UNQUOTED(MODULE_DATA_DIR, "$MODULEDIR",
                   [Installation directory for Arc plugin data])

PKG_CHECK_MODULES(GVC, libpulse >= $PULSE_MIN_VERS libpulse-mainloop-glib gobject-2.0)

AC_PATH_PROG(GLIB_COMPILE_RESOURCES, glib-compile-resources)

AC_CONFIG_MACRO_DIR([m4])

GOBJECT_INTROSPECTION_CHECK([1.44.0])

# Need Vala.
AM_PROG_VALAC([0.28], [], [AC_MSG_ERROR([valac is required to build Arc Desktop])])


AC_SUBST(VALAFLAGS)

GETTEXT_PACKAGE=arc-desktop
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, ["$GETTEXT_PACKAGE"], [Define the gettext package to be used])

AC_CONFIG_FILES([Makefile
                data/Makefile
                gvc/Makefile
                lib/Makefile
                plugin/Makefile
                plugin/arc-1.0.pc
                raven/Makefile
                panel/Makefile
                panel/applets/Makefile
                panel/applets/budgie-menu/Makefile])
AC_OUTPUT

AC_MSG_RESULT([
        arc-desktop $VERSION
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
])
