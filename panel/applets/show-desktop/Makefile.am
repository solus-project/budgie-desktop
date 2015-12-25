if ENABLE_SHOW_DESKTOP_PLUGIN

-include $(top_srcdir)/common.mk

EXTRA_DIST =
pkglib_LTLIBRARIES =
plugindir = $(MODULEDIR)
plugin_DATA =


plugin_DATA += \
	ShowDesktopApplet.plugin

EXTRA_DIST += \
	$(plugin_DATA)

plugin_LTLIBRARIES = libshowdesktopapplet.la

libshowdesktopapplet_la_SOURCES = \
	ShowDesktopApplet.vala

libshowdesktopapplet_la_CFLAGS = \
	$(ARC_BASE_CFLAGS) \
	$(ARC_PLUGIN_CFLAGS) \
	$(SHOW_DESKTOP_PLUGIN_CFLAGS) \
	-DWNCK_I_KNOW_THIS_IS_UNSTABLE \
	$(DECLARATIONS)

libshowdesktopapplet_la_LIBADD = \
	${top_builddir}/plugin/libarc-plugin.la \
	$(ARC_BASE_LIBS) \
	$(ARC_PLUGIN_LIBS) \
	$(SHOW_DESKTOP_PLUGIN_LIBS)

libshowdesktopapplet_la_LDFLAGS = \
	$(MODULE_FLAGS) \
	$(AM_LDFLAGS)

libshowdesktopapplet_la_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg libwnck-3.0 \
	--pkg gio-unix-2.0 \
	--pkg libpeas-1.0 \
	--pkg PeasGtk-1.0 \
	--pkg arc-1.0 \
	--vapidir=${top_srcdir}/plugin

endif
