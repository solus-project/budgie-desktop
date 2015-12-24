AC_INIT([Arc Desktop], 1, [ikey@solus-project.com], [arc-desktop], [https://solus-project.com/])
AM_INIT_AUTOMAKE([-Wno-portability no-dist-gzip dist-xz foreign subdir-objects])
AC_PROG_CC
AC_PROG_CC_STDC

AC_PREFIX_DEFAULT(/usr/local)
AM_SILENT_RULES([yes])
AC_CONFIG_MACRO_DIR([m4])

GLIB_GSETTINGS

m4_define([mutter_required_version], [3.18.0])
m4_define([glib_required_version], [2.44.0])
m4_define([gtk_required_version], [3.16.0])
m4_define([peas_required_version], [1.8.0])
m4_define([gdesktop_required_version], [3.18.0])
m4_define([pulse_required_version], [2.0])
m4_define([gsettings_required_version], [3.18.0])

GOBJECT_INTROSPECTION_CHECK([1.44.0])
AC_PATH_PROG(GLIB_COMPILE_RESOURCES, glib-compile-resources)
AM_PROG_VALAC([0.28], [], [AC_MSG_ERROR([valac is required to build Arc Desktop])])
AC_SUBST(VALAFLAGS)


PULSE_MIN_VERS=2.0
PKG_CHECK_MODULES(GVC,
                 [
                   libpulse >= pulse_required_version,
                   libpulse-mainloop-glib >= pulse_required_version,
                   gobject-2.0 >= glib_required_version
                 ]
)

# Specific requirements
PKG_CHECK_MODULES([UUID], [uuid])

PKG_CHECK_MODULES([ARC_BASE],
                [
                 gobject-2.0 >= glib_required_version,
                 gio-2.0 >= glib_required_version,
                 gio-unix-2.0 >= glib_required_version,
                 gtk+-3.0 >= gtk_required_version
                ]
)

# Plugin global deps
PKG_CHECK_MODULES([ARC_PLUGIN],
                 [
                  libpeas-gtk-1.0 >= peas_required_version
                 ]
)

# Additional WM deps
PKG_CHECK_MODULES([ARC_WM],
                [
                 libmutter >= mutter_required_version,
                 gnome-desktop-3.0 >= gdesktop_required_version,
                 gsettings-desktop-schemas >= gsettings_required_version
                ]
)



MODULEDIR="${libdir}/arc-desktop/plugins"
AC_SUBST(MODULEDIR)
AC_DEFINE_UNQUOTED(MODULEDIR, "$MODULEDIR",
                   [Installation directory for Arc plugins])

# Technically unused right now but might be used in the future
MODULE_DATA_DIR="${datadir}/share/arc-desktop/plugins"
AC_SUBST(MODULE_DATA_DIR)
AC_DEFINE_UNQUOTED(MODULE_DATA_DIR, "$MODULEDIR",
                   [Installation directory for Arc plugin data])


# Got this idea from gnome-builder :)
m4_include([panel/applets/budgie-menu/configure.ac])
m4_include([panel/applets/clock/configure.ac])
m4_include([panel/applets/icon-tasklist/configure.ac])
m4_include([panel/applets/tasklist/configure.ac])
m4_include([panel/applets/notifications/configure.ac])
m4_include([panel/applets/separator/configure.ac])

LT_PREREQ(2.2)
LT_INIT([disable-static])

AH_TOP([#ifndef CONFIG_H_INCLUDED
	#define CONFIG_H_INCLUDED 1])
AH_BOTTOM([#endif])
AC_CONFIG_HEADERS([config.h])

AC_CONFIG_FILES([Makefile
                data/arc-panel.desktop
                data/Makefile
                gvc/Makefile
                lib/Makefile
                plugin/Makefile
                plugin/arc-1.0.pc
                raven/Makefile
                panel/arc-panel.desktop.in
                panel/Makefile
                panel/applets/Makefile
                session/arc-desktop.desktop.in
                session/arc-desktop.session.in
                session/arc-desktop
                session/Makefile
                wm/arc-wm.desktop
                wm/Makefile
                po/Makefile.in])

IT_PROG_INTLTOOL([0.50.0])
GETTEXT_PACKAGE=arc-desktop
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, "$GETTEXT_PACKAGE",
                   [The prefix for our gettext translation domains.])

AC_OUTPUT

AM_GLIB_GNU_GETTEXT
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
        clock:                  always
        notifications:          always
        separator:              always
        tasklist:               ${have_wnck}
])
