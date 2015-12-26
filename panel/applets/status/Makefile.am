if ENABLE_STATUS_PLUGIN

-include $(top_srcdir)/common.mk

EXTRA_DIST =
pkglib_LTLIBRARIES =
plugindir = $(MODULEDIR)
plugin_DATA =


plugin_DATA += \
	StatusApplet.plugin

EXTRA_DIST += \
	$(plugin_DATA)

plugin_LTLIBRARIES = libstatusapplet.la

libstatusapplet_la_SOURCES = \
	StatusApplet.vala \
	PowerIndicator.vala \
	SoundIndicator.vala

libstatusapplet_la_CFLAGS = \
	$(BUDGIE_BASE_CFLAGS) \
	$(BUDGIE_PLUGIN_CFLAGS) \
	$(STATUS_PLUGIN_CFLAGS) \
	$(GVC_CFLAGS) \
	$(DECLARATIONS)

libstatusapplet_la_LIBADD = \
	${top_builddir}/plugin/libbudgie-plugin.la \
	${top_builddir}/gvc/libgvc.la \
	$(BUDGIE_BASE_LIBS) \
	$(BUDGIE_PLUGIN_LIBS) \
	$(GVC_LIBS) \
	$(STATUS_PLUGIN_LIBS)

libstatusapplet_la_LDFLAGS = \
	$(MODULE_FLAGS) \
	$(AM_LDFLAGS)

libstatusapplet_la_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg gvc-1.0 \
	--pkg upower-glib-1.0 \
	--pkg gio-unix-2.0 \
	--pkg libpeas-1.0 \
	--pkg PeasGtk-1.0 \
	--pkg budgie-1.0 \
	--pkg posix \
	--vapidir=${top_srcdir}/plugin \
	--vapidir=${top_srcdir}/vapi

endif
