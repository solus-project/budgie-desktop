-include $(top_srcdir)/common.mk

EXTRA_DIST =
pkglib_LTLIBRARIES =
plugindir = $(libdir)/budgie-desktop
plugin_DATA =

plugin_DATA += \
	TrayApplet.plugin

EXTRA_DIST += \
	$(plugin_DATA)

pkglib_LTLIBRARIES += libtrayapplet.la

libtrayapplet_la_SOURCES = \
	TrayApplet.vala

libtrayapplet_la_CFLAGS = \
	$(GOBJECT_CFLAGS) \
	$(GTK3_CFLAGS) \
	$(LIBPEAS_CFLAGS)

libtrayapplet_la_LIBADD = \
	${top_builddir}/budgie-plugin/libbudgie-plugin.la \
	${top_builddir}/imports/natray/libnatray.la \
	$(GTK3_LIBS) \
	$(LIBPEAS_LIBS)

libtrayapplet_la_LDFLAGS = \
	-module \
	-avoid-version \
	$(AM_LDFLAGS)

libtrayapplet_la_VALAFLAGS = \
	--vapidir=${top_builddir}/budgie-plugin \
	--vapidir=${top_builddir}/imports/natray \
	--pkg gtk+-3.0 \
	--pkg libpeas-1.0 \
	--pkg PeasGtk-1.0 \
	--pkg budgie-1.0 \
	--pkg natray-1.0


dist-hook:
	cd $(distdir) && \
	rm $(libtrayapplet_la_SOURCES:.vala=.c) libtrayapplet_la_vala.stamp
