#!/bin/sh

# Borrowed from: https://github.com/vinszent/gnome-twitch/blob/master/meson_post_install.sh
# <3 TingPing ^^
if [ -z $DESTDIR ]; then

	PREFIX=${MESON_INSTALL_PREFIX:-/usr}

	echo 'Compiling GSchema'
	glib-compile-schemas "$PREFIX/share/glib-2.0/schemas"
	echo 'Updating desktop database'
	update-desktop-database -q
	echo 'Updating icon cache'
	gtk-update-icon-cache -q -t -f "$PREFIX/share/icons/hicolor"

fi
