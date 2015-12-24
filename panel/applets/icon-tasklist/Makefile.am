if ENABLE_ICON_TASKLIST_PLUGIN

-include $(top_srcdir)/common.mk

EXTRA_DIST =
pkglib_LTLIBRARIES =
plugindir = $(MODULEDIR)
plugin_DATA =


plugin_DATA += \
	IconTasklistApplet.plugin

EXTRA_DIST += \
	$(plugin_DATA) \
	com.solus-project.icon-tasklist.gschema.xml

plugin_LTLIBRARIES = libicontasklistapplet.la

libicontasklistapplet_la_SOURCES = \
	IconTasklistApplet.vala

libicontasklistapplet_la_CFLAGS = \
	$(ARC_BASE_CFLAGS) \
	$(ARC_PLUGIN_CFLAGS) \
	$(ICON_TASKLIST_PLUGIN_CFLAGS) \
	-DWNCK_I_KNOW_THIS_IS_UNSTABLE \
	$(DECLARATIONS)

libicontasklistapplet_la_LIBADD = \
	${top_builddir}/plugin/libarc-plugin.la \
	$(ARC_BASE_LIBS) \
	$(ARC_PLUGIN_LIBS) \
	$(ICON_TASKLIST_PLUGIN_LIBS)

libicontasklistapplet_la_LDFLAGS = \
	$(MODULE_FLAGS) \
	$(AM_LDFLAGS)

libicontasklistapplet_la_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg libwnck-3.0 \
	--pkg gio-unix-2.0 \
	--pkg libpeas-1.0 \
	--pkg PeasGtk-1.0 \
	--pkg arc-1.0 \
	--vapidir=${top_srcdir}/plugin

gsettings_SCHEMAS = \
	com.solus-project.icon-tasklist.gschema.xml

@GSETTINGS_RULES@

endif
