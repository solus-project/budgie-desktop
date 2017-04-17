#!/bin/bash
set -e

git submodule init
git submodule update

# Script for ikey because he went with meson. *shrug*
VERSION="10.3.1"
NAME="budgie-desktop"
git-archive-all.sh --format tar --prefix ${NAME}-${VERSION}/ --verbose -t HEAD ${NAME}-${VERSION}.tar
xz -9 "${NAME}-${VERSION}.tar"

gpg --armor --detach-sign "${NAME}-${VERSION}.tar.xz"
gpg --verify "${NAME}-${VERSION}.tar.xz.asc"               
