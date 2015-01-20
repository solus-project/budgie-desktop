-include $(top_srcdir)/common.mk

EXTRA_DIST =
pkglib_LTLIBRARIES =
plugindir = $(libdir)/budgie-desktop
plugin_DATA =



plugin_DATA += \
	MenubarApplet.plugin

EXTRA_DIST += \
	$(plugin_DATA)

pkglib_LTLIBRARIES += libmenubarapplet.la

libmenubarapplet_la_SOURCES = \
	MenubarApplet.vala

libmenubarapplet_la_CFLAGS = \
	$(GOBJECT_CFLAGS) \
	$(GTK3_CFLAGS) \
	$(GMENU_CFLAGS) \
	$(GIO_UNIX_CFLAGS) \
	$(LIBPEAS_CFLAGS) \
	-DGMENU_I_KNOW_THIS_IS_UNSTABLE \
	-DMODULE_DIR=\"$(MODULEDIR)\" \
	-DMODULE_DATA_DIR=\"$(MODULE_DATA_DIR)\" \
	-DDATADIR=\"$(datadir)/budgie-desktop\"


libmenubarapplet_la_LIBADD = \
	${top_builddir}/budgie-plugin/libbudgie-plugin.la \
	$(GTK3_LIBS) \
	$(GMENU_LIBS) \
	$(GIO_UNIX_LIBS) \
	$(LIBPEAS_LIBS)

libmenubarapplet_la_LDFLAGS = \
	-module \
	-avoid-version \
	$(AM_LDFLAGS)

libmenubarapplet_la_VALAFLAGS = \
	--vapidir=${top_builddir}/budgie-plugin \
	--vapidir=${top_builddir}/panel \
	--pkg gtk+-3.0 \
	--pkg panelconfig \
	--pkg libgnome-menu-3.0 \
	--pkg gio-unix-2.0 \
	--pkg libpeas-1.0 \
	--pkg PeasGtk-1.0 \
	--pkg budgie-1.0

dist-hook:
	cd $(distdir) && \
	rm $(libmenubarapplet_la_SOURCES:.vala=.c) libmenubarapplet_la_vala.stamp
