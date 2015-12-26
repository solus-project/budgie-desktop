#!/bin/sh
# Run this to generate all the initial makefiles, etc.

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
AUTORECONF=`which autoreconf`
if test -z $AUTORECONF;
then
  echo "*** No autoreconf found, please install it ***"
  exit 1
else
  libtoolize -i || exit $?
  autoreconf --force --install || exit $?
fi

cd "$prevdir"
test -n "$NOCONFIGURE" || "$srcdir/configure" "$@"
