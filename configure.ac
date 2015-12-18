AC_INIT([Arc Desktop], 1, [ikey@solus-project.com], [arc-desktop], [https://solus-project.com/])
AM_INIT_AUTOMAKE([-Wno-portability no-dist-gzip dist-xz foreign subdir-objects])
AC_PROG_CC
AC_PROG_CC_STDC
AC_CONFIG_HEADERS([config.h])
AC_PREFIX_DEFAULT(/usr/local)
AM_SILENT_RULES([yes])

GLIB_GSETTINGS

GETTEXT_PACKAGE=arc-desktop
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, "$GETTEXT_PACKAGE",
                   [The prefix for our gettext translation domains.])


m4_define([mutter_required_version], [3.18.0])
m4_define([glib_required_version], [2.44.0])
m4_define([gtk_required_version], [3.16.0])
m4_define([peas_required_version], [1.8.0])
m4_define([gdesktop_required_version], [3.18.0])

# Package requirements
PKG_CHECK_MODULES([GOBJECT], [gobject-2.0 >= glib_required_version])
PKG_CHECK_MODULES([GIO], [gio-2.0 >= glib_required_version])
PKG_CHECK_MODULES([GTK3], [gtk+-3.0 >= gtk_required_version])
PKG_CHECK_MODULES([GIO_UNIX], [gio-unix-2.0 >= glib_required_version])
PKG_CHECK_MODULES([UUID], [uuid])


PKG_CHECK_MODULES([ARC_BASE],
                [
                 gobject-2.0 >= glib_required_version,
                 gio-2.0 >= glib_required_version,
                 gio-unix-2.0 >= glib_required_version,
                 gtk+-3.0 >= gtk_required_version
                ]
)

PKG_CHECK_MODULES([ARC_PLUGIN],
                 [
                  libpeas-gtk-1.0 >= peas_required_version
                 ]
)

PKG_CHECK_MODULES([ARC_WM],
                [
                 libmutter >= mutter_required_version,
                 gnome-desktop-3.0 >= gdesktop_required_version
                ]
)


PULSE_MIN_VERS=2.0

MODULEDIR="${libdir}/arc-desktop/plugins"
AC_SUBST(MODULEDIR)
AC_DEFINE_UNQUOTED(MODULEDIR, "$MODULEDIR",
                   [Installation directory for Arc plugins])

# Technically unused right now but might be used in the future
MODULE_DATA_DIR="${datadir}/share/arc-desktop/plugins"
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


# Got this idea from gnome-builder :)
dnl Plugins
m4_include([panel/applets/budgie-menu/configure.ac])
m4_include([panel/applets/tasklist/configure.ac])

LT_PREREQ(2.2)
LT_INIT([disable-static])

AC_CONFIG_FILES([Makefile
                data/arc-panel.desktop
                data/Makefile
                gvc/Makefile
                lib/Makefile
                plugin/Makefile
                plugin/arc-1.0.pc
                raven/Makefile
                panel/arc-panel.desktop
                panel/Makefile
                panel/applets/Makefile
                session/arc-desktop.desktop
                session/arc-desktop.session
                session/arc-desktop
                session/Makefile
                wm/arc-wm.desktop
                wm/Makefile])
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

        Plugins:
        =======

        budgie-menu:            always
        tasklist:               ${have_wnck}
])
