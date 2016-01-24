#!/bin/sh
# Run this to generate all the initial makefiles, etc.
# NOTE:
#   We automatically clone the gvc submodule, and this is included within
#   the "make dist" tarball- you need this to package Budgie!
#   See issue: 303
#
srcdir=`dirname $0`
test -n "$srcdir" || srcdir=`dirname "$0"`
test -n "$srcdir" || srcdir=.

PKG_NAME="budgie-desktop"
prevdir="$PWD"
cd "$srcdir"

# Fetch submodules if needed
if test ! -f gvc/Makefile.am;
then
  echo "+ Setting up submodules"
  git submodule init
fi
git submodule update

intltoolize --force
gtkdocize || exit 1
AUTORECONF=`which autoreconf`
if test -z $AUTORECONF;
then
  echo "*** No autoreconf found, please install it ***"
  exit 1
else
  libtoolize -i || exit $?
  autoreconf --force --install || exit $?
fi

DEF_OPTS="--prefix=/usr --sysconfdir=/etc"

cd "$prevdir"
test -n "$NOCONFIGURE" || "$srcdir/configure" ${DEF_OPTS} "$@"
