-include $(top_srcdir)/common.mk

EXTRA_DIST =
pkglib_LTLIBRARIES =
plugindir = $(libdir)/budgie-desktop
plugin_DATA =



plugin_DATA += \
	TaskListApplet.plugin

EXTRA_DIST += \
	$(plugin_DATA)

pkglib_LTLIBRARIES += libtasklistapplet.la

libtasklistapplet_la_SOURCES = \
	TaskListApplet.vala

libtasklistapplet_la_CFLAGS = \
	$(GOBJECT_CFLAGS) \
	$(GTK3_CFLAGS) \
	$(WNCK3_CFLAGS) \
	$(LIBPEAS_CFLAGS) \
	-DWNCK_I_KNOW_THIS_IS_UNSTABLE

libtasklistapplet_la_LIBADD = \
	${top_builddir}/budgie-plugin/libbudgie-plugin.la \
	$(GTK3_LIBS) \
	$(WNCK3_LIBS) \
	$(LIBPEAS_LIBS)

libtasklistapplet_la_LDFLAGS = \
	-module \
	-avoid-version \
	$(AM_LDFLAGS)

libtasklistapplet_la_VALAFLAGS = \
	--vapidir=${top_builddir}/budgie-plugin \
	--pkg gtk+-3.0 \
	--pkg libpeas-1.0 \
	--pkg libwnck-3.0 \
	--pkg PeasGtk-1.0 \
	--pkg budgie-1.0
