dnl vapigen.m4
dnl
dnl Copyright 2012 Evan Nemerson
dnl
dnl This library is free software; you can redistribute it and/or
dnl modify it under the terms of the GNU Lesser General Public
dnl License as published by the Free Software Foundation; either
dnl version 2.1 of the License, or (at your option) any later version.
dnl
dnl This library is distributed in the hope that it will be useful,
dnl but WITHOUT ANY WARRANTY; without even the implied warranty of
dnl MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
dnl Lesser General Public License for more details.
dnl
dnl You should have received a copy of the GNU Lesser General Public
dnl License along with this library; if not, write to the Free Software
dnl Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA

# VAPIGEN_CHECK([VERSION], [API_VERSION], [FOUND_INTROSPECTION], [DEFAULT])
# --------------------------------------
# Check vapigen existence and version
#
# See http://live.gnome.org/Vala/UpstreamGuide for detailed documentation
#
#
#
# Butchered by Ikey to suit Budgie
AC_DEFUN([VAPIGEN_CHECK_FORCE],
[

        AS_IF([test "x$2" = "x"], [
                vapigen_pkg_name=vapigen
        ], [
                vapigen_pkg_name=vapigen-$2
        ])
        AS_IF([test "x$1" = "x"], [
                vapigen_pkg="$vapigen_pkg_name"
        ], [
                vapigen_pkg="$vapigen_pkg_name >= $1"
        ])

        PKG_PROG_PKG_CONFIG

        PKG_CHECK_EXISTS([$vapigen_pkg])

        AC_MSG_CHECKING([for vapigen])


        VAPIGEN=`$PKG_CONFIG --variable=vapigen $vapigen_pkg_name`
        VAPIGEN_MAKEFILE=`$PKG_CONFIG --variable=datadir $vapigen_pkg_name`/vala/Makefile.vapigen
        AS_IF([test "x$2" = "x"], [
        VAPIGEN_VAPIDIR=`$PKG_CONFIG --variable=vapidir $vapigen_pkg_name`
        ], [
        VAPIGEN_VAPIDIR=`$PKG_CONFIG --variable=vapidir_versioned $vapigen_pkg_name`
        ])


        AC_SUBST([VAPIGEN])
        AC_SUBST([VAPIGEN_VAPIDIR])
        AC_SUBST([VAPIGEN_MAKEFILE])
])
