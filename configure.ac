AC_INIT([Budgie Desktop], 1, [ikey.doherty@gmail.com], [budgie-desktop], [http://ikeydoherty.github.io/])
AM_INIT_AUTOMAKE([-Wno-portability no-dist-gzip dist-xz foreign])
AC_PROG_CC
AC_PROG_CC_STDC
LT_PREREQ(2.2)
AC_CONFIG_HEADERS([config.h])
AC_PREFIX_DEFAULT(/usr/local)
AM_SILENT_RULES([yes])
LT_INIT([disable-static])

# Package requirements
PKG_CHECK_MODULES([GOBJECT], [gobject-2.0 >= 2.38.0])
PKG_CHECK_MODULES([GIO], [gio-2.0 >= 2.38.0])
PKG_CHECK_MODULES([GTK3], [gtk+-3.0 >= 3.10.0])
# We require Mutter
PKG_CHECK_MODULES([MUTTER], [libmutter >= 3.10.1])

AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_FILES(Makefile
                session/Makefile
                wm/Makefile)
AC_OUTPUT

