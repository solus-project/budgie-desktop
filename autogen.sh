#!/bin/bash
# Run this to generate all the initial makefiles, etc.

srcdir=`dirname $0`
test -z "$srcdir" && srcdir=.

PKG_NAME="budgie-desktop"

(test -f $srcdir/configure.ac) || {
    echo -n "**Error**: Directory "\`$srcdir\'" does not look like the"
    echo " top-level budgie-desktop directory"
    exit 1
}

# Fetch submodules if needed
if test ! -f gvc/Makefile.am;
then
  echo "+ Setting up submodules"
  git submodule init
fi
git submodule update

which gnome-autogen.sh || {
    echo "You need to install gnome-common from GNOME Git (or from"
    echo "your OS vendor's package manager)."
    exit 1
}
USE_COMMON_DOC_BUILD=no . gnome-autogen.sh
