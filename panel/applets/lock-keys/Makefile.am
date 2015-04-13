-include $(top_srcdir)/common.mk

EXTRA_DIST =
pkglib_LTLIBRARIES =
plugindir = $(libdir)/budgie-desktop
plugin_DATA =



plugin_DATA += \
	LockKeysApplet.plugin

EXTRA_DIST += \
	$(plugin_DATA)

pkglib_LTLIBRARIES += liblockkeysapplet.la

liblockkeysapplet_la_SOURCES = \
	LockKeysApplet.vala

liblockkeysapplet_la_CFLAGS = \
	$(GOBJECT_CFLAGS) \
	$(GTK3_CFLAGS) \
	$(LIBPEAS_CFLAGS)

liblockkeysapplet_la_LIBADD = \
	${top_builddir}/budgie-plugin/libbudgie-plugin.la \
	$(GTK3_LIBS) \
	$(LIBPEAS_LIBS)

liblockkeysapplet_la_LDFLAGS = \
	-module \
	-avoid-version \
	$(AM_LDFLAGS)

liblockkeysapplet_la_VALAFLAGS = \
	--vapidir=${top_builddir}/budgie-plugin \
	--pkg gtk+-3.0 \
	--pkg libpeas-1.0 \
	--pkg PeasGtk-1.0 \
	--pkg budgie-1.0
