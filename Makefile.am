ACLOCAL_AMFLAGS = -I m4
AM_CFLAGS =

EXTRA_DIST = \
	${top_srcdir}/common.mk \
	${top_srcdir}/README.md \
	${top_srcdir}/LICENSE \
	${top_srcdir}/LICENSE.LGPL2.1 \
	${top_srcdir}/vapi/gvc-1.0.vapi \
	${top_srcdir}/vapi/libmutter.vapi \
	${top_srcdir}/vapi/libmutter.deps \
	${top_srcdir}/vapi/libuuid.vapi \
	${top_srcdir}/vapi/gnome-desktop-3.0.vapi \
	${top_srcdir}/vapi/gsettings-desktop-schemas.vapi \
	${top_srcdir}/vapi/upower-glib-1.0.vapi \
	${top_srcdir}/vapi/polkit-gobject-1.vapi \
	${top_srcdir}/vapi/polkit-agent-1.vapi \
	${top_srcdir}/vapi/GnomeBluetooth-1.0.vapi \
	${top_srcdir}/vapi/accountsservice.vapi

DISTCHECK_CONFIGURE_FLAGS = --enable-introspection

NULL =
CLEANFILES =

SUBDIRS = \
	data \
	gvc \
	theme \
	src \
	po \
	docs
