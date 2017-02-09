AC_INIT([Budgie Desktop], 10.2.9, [ikey@solus-project.com], [budgie-desktop], [https://solus-project.com/])
AM_INIT_AUTOMAKE([-Wno-portability no-dist-gzip dist-xz foreign subdir-objects 1.9 tar-ustar])
AC_PROG_CC
AC_PROG_CC_STDC

AC_PREFIX_DEFAULT(/usr/local)
AM_SILENT_RULES([yes])
AC_CONFIG_MACRO_DIR([m4])

GLIB_GSETTINGS

m4_define([mutter_required_version], [3.16.0])
m4_define([mutter_goes_private_version], [3.21.0])
m4_define([glib_required_version], [2.44.0])
m4_define([gtk_required_version], [3.16.0])
m4_define([peas_required_version], [1.8.0])
m4_define([gdesktop_required_version], [3.16.0])
m4_define([pulse_required_version], [2.0])
m4_define([gsettings_required_version], [3.16.0])
m4_define([polkit_required_version], [0.105])
m4_define([accountsservice_version], [0.6.40])
m4_define([ibus_required_version], [1.5.10])

GOBJECT_INTROSPECTION_CHECK([1.42.0])
AC_PATH_PROG(GLIB_COMPILE_RESOURCES, glib-compile-resources)
AM_PROG_VALAC([0.28], [], [AC_MSG_ERROR([valac is required to build Budgie Desktop])])
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

PKG_CHECK_MODULES([BUDGIE_BASE],
                [
                 gobject-2.0 >= glib_required_version,
                 gio-2.0 >= glib_required_version,
                 gio-unix-2.0 >= glib_required_version,
                 gtk+-3.0 >= gtk_required_version
                ]
)

PKG_CHECK_MODULES([LIBSESSION],
                [
                 gio-unix-2.0 >= glib_required_version,
                 gobject-2.0 >= glib_required_version
                ]
)

# Plugin global deps
PKG_CHECK_MODULES([BUDGIE_PLUGIN],
                 [
                  libpeas-gtk-1.0 >= peas_required_version
                 ]
)

# Additional WM deps
PKG_CHECK_MODULES([BUDGIE_WM],
                [
                 libmutter >= mutter_required_version,
                 gnome-desktop-3.0 >= gdesktop_required_version,
                 gsettings-desktop-schemas >= gsettings_required_version,
                 ibus-1.0 >= ibus_required_version
                ]
)

# Runtime dialog, avoid unnecessary linking
PKG_CHECK_MODULES([RUNDIALOG],
                [
                 gtk+-3.0 >= gtk_required_version
                ]
)

# Check if we have the mutter private API cruft.
PKG_CHECK_MODULES(MUTTER_PRIVATE, libmutter >= mutter_goes_private_version,
        [have_cranky_mutter=yes], [have_cranky_mutter=no]
)

if test x$have_cranky_mutter = "xyes"; then
        MUTTER_TYPELIB_DIR=`$PKG_CONFIG --variable=typelibdir libmutter`
        AC_SUBST(MUTTER_TYPELIB_DIR)
fi

AM_CONDITIONAL(HAVE_CRANKY_MUTTER, test x$have_cranky_mutter = xyes)

m4_include([src/config/configure.ac])

# Got this idea from gnome-builder :)
m4_include([src/imports/configure.ac])
m4_include([src/panel/applets/budgie-menu/configure.ac])
m4_include([src/panel/applets/clock/configure.ac])
m4_include([src/panel/applets/icon-tasklist/configure.ac])
m4_include([src/panel/applets/keyboard-layout/configure.ac])
m4_include([src/panel/applets/lock-keys/configure.ac])
m4_include([src/panel/applets/tasklist/configure.ac])
m4_include([src/panel/applets/notifications/configure.ac])
m4_include([src/panel/applets/places-indicator/configure.ac])
m4_include([src/panel/applets/raven-trigger/configure.ac])
m4_include([src/panel/applets/separator/configure.ac])
m4_include([src/panel/applets/show-desktop/configure.ac])
m4_include([src/panel/applets/spacer/configure.ac])
m4_include([src/panel/applets/status/configure.ac])
m4_include([src/panel/applets/tray/configure.ac])
m4_include([src/panel/applets/user-indicator/configure.ac])
m4_include([src/panel/applets/workspaces/configure.ac])
m4_include([src/polkit/configure.ac])
m4_include([src/daemon/configure.ac])

# Find the libraries containing animation functions we need.
BACKLIBS="$LIBS"
AC_CHECK_LIB([m], [sin], [], [AC_MSG_FAILURE([Missing required sin function])])
AC_CHECK_LIB([m], [cos], [], [AC_MSG_FAILURE([Missing required cos function])])
AC_CHECK_LIB([m], [sqrt], [], [AC_MSG_FAILURE([Missing required sqrt function])])
AC_CHECK_LIB([m], [floor], [], [AC_MSG_FAILURE([Missing required floor function])])
AC_CHECK_LIB([m], [pow], [], [AC_MSG_FAILURE([Missing required pow function])])
LIBS="$BACKLIBS"

LT_PREREQ(2.2)
LT_INIT([disable-static])

AH_TOP([#ifndef CONFIG_H_INCLUDED
	#define CONFIG_H_INCLUDED 1])
AH_BOTTOM([#endif])
AC_CONFIG_HEADERS([config.h])

# check for gtk-doc
m4_ifdef([GTK_DOC_CHECK], [
GTK_DOC_CHECK([1.14],[--flavour no-tmpl])
],[
AM_CONDITIONAL([ENABLE_GTK_DOC], false)
])

AC_ARG_ENABLE(stateless, AS_HELP_STRING([--enable-stateless], [enable stateless configuration]))
if test "x$enable_stateless" = "xyes" ; then
    AC_DEFINE([STATELESS], [1], [Using stateless configuration])
    adl_RECURSIVE_EVAL(["${datadir}/xdg"], [XDGDIR])
else
    enable_stateless="no"
    adl_RECURSIVE_EVAL(["${sysconfdir}/xdg"], [XDGDIR])
fi

AC_SUBST(XDGDIR)

AM_CONDITIONAL([STATELESS_CONFIG], [test x$enable_stateless = "xyes"])

AC_CONFIG_FILES([Makefile
                src/config/Makefile
                data/budgie-panel.desktop
                data/Makefile
                src/Makefile
                src/gvc/Makefile
                src/lib/Makefile
                src/libsession/Makefile
                src/plugin/Makefile
                src/plugin/budgie-1.0.pc
                src/raven/Makefile
                src/panel/budgie-panel.desktop.in
                src/panel/Makefile
                src/panel/applets/Makefile
                src/rundialog/Makefile
                src/session/budgie-desktop.desktop.in
                src/session/budgie-desktop.session.in
                src/session/budgie-desktop
                src/session/Makefile
                src/theme/budgie-theme-1.0.pc
                src/theme/Makefile
                po/Makefile.in
                docs/Makefile])

IT_PROG_INTLTOOL([0.50.0])
GETTEXT_PACKAGE=budgie-desktop
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, "$GETTEXT_PACKAGE",
                   [The prefix for our gettext translation domains.])

AC_PATH_PROG([GLIB_MKENUMS], [glib-mkenums])

AC_OUTPUT

AM_GLIB_GNU_GETTEXT

AC_MSG_RESULT([
        budgie-desktop $VERSION
        =====================

        prefix:                 ${prefix}
        libdir:                 ${libdir}
        sysconfdir:             ${sysconfdir}
        exec_prefix:            ${exec_prefix}
        bindir:                 ${bindir}
        datarootdir:            ${datarootdir}

        compiler:               ${CC}
        cflags:                 ${CFLAGS}
        ldflags:                ${LDFLAGS}

        stateless:              ${enable_stateless}
        xdg directory:          ${XDGDIR}

        mutter private api:     ${have_cranky_mutter}

        Plugins:
        ========

        natray:                 ${have_natray}

        budgie-menu:            always
        clock:                  always
        icon-tasklist           ${have_wnck}
        notifications           always
        separator:              always
        spacer:                 always
        show-desktop:           ${have_wnck}
        tasklist:               ${have_wnck}
        places-indicator:       always
        raven-trigger:          always
        status:                 ${have_status}
        tray:                   ${have_natray}
        user-indicator:         ${have_user_indicator}
        workspaces:             ${have_wnck}

        Polkit Agent:           always
])
