if ENABLE_TRAY_PLUGIN

-include $(top_srcdir)/common.mk

EXTRA_DIST =
pkglib_LTLIBRARIES =
plugindir = $(MODULEDIR)
plugin_DATA =


plugin_DATA += \
	TrayApplet.plugin

EXTRA_DIST += \
	$(plugin_DATA)

plugin_LTLIBRARIES = libtrayapplet.la

libtrayapplet_la_SOURCES = \
	TrayApplet.vala

libtrayapplet_la_CFLAGS = \
	$(BUDGIE_BASE_CFLAGS) \
	$(BUDGIE_PLUGIN_CFLAGS) \
	$(NATRAY_CFLAGS) \
	$(DECLARATIONS) \
	-I${top_srcdir}/imports/natray

libtrayapplet_la_LIBADD = \
	${top_builddir}/plugin/libbudgie-plugin.la \
	$(BUDGIE_BASE_LIBS) \
	$(BUDGIE_PLUGIN_LIBS) \
	$(NATRAY_LIBS) \
	${top_builddir}/imports/natray/libnatray.la

libtrayapplet_la_LDFLAGS = \
	$(MODULE_FLAGS) \
	$(AM_LDFLAGS)

libtrayapplet_la_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg natray-1.0 \
	--pkg libwnck-3.0 \
	--pkg gio-unix-2.0 \
	--pkg libpeas-1.0 \
	--pkg PeasGtk-1.0 \
	--pkg budgie-1.0 \
	--vapidir=${top_srcdir}/plugin \
	--vapidir=${top_srcdir}/imports/natray

endif
